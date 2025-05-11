#!/usr/bin/env perl
use strict;
use warnings;
use POSIX qw(floor);

# — INPUT/OUTPUT —
my $in  = shift @ARGV or die "Usage: $0 <in.fasta> [out.txt]\n";
my $out = shift @ARGV or die "Usage: $0 <in.fasta> [out.txt]\n";

open my $IN,  '<', $in  or die $!;
open my $OUT, '>', $out or die $!;

# slurp (strip headers & non‐ACGT)
local $/;
my $raw = <$IN>;
close $IN;
$raw =~ s/>.*?\n//gs;
$raw =~ s/[^ACGTacgt]//g;
my $seq = lc $raw;
my $len = length $seq;
my @cods = ($seq =~ /(...)/g);
my $n_codon = @cods;

# — 1) mono‐nuc counts, GC/AT% —
my %nt; $nt{$_}++ for split //, $seq;
my $A = $nt{a}||0;  my $T = $nt{t}||0;
my $G = $nt{g}||0;  my $C = $nt{c}||0;
my $GCpct = $len ? sprintf("%.2f",($G+$C)/$len*100) : 0;
my $ATpct = $len ? sprintf("%.2f",($A+$T)/$len*100) : 0;

# — 2) skews —
my $GCskew = ($G+$C) ? sprintf("%.3f",($G-$C)/($G+$C)) : 'NA';
my $ATskew = ($A+$T) ? sprintf("%.3f",($A-$T)/($A+$T)) : 'NA';

# — 3) dinucleotide counts —
my %di;
while($seq =~ /(..)/g){ $di{$1}++ }

# — 4) codon counts & RSCU & ENc —
my %codon;
$codon{$_}++ for @cods;

# — full codon→AA map (standard) —
my %c2aa = (
  # Phenylalanine
  ttt => 'F', ttc => 'F',
  # Leucine
  tta => 'L', ttg => 'L', ctt => 'L', ctc => 'L', cta => 'L', ctg => 'L',
  # Isoleucine & Methionine
  att => 'I', atc => 'I', ata => 'I', atg => 'M',
  # Valine
  gtt => 'V', gtc => 'V', gta => 'V', gtg => 'V',

  # Serine
  tct => 'S', tcc => 'S', tca => 'S', tcg => 'S', agt => 'S', agc => 'S',
  # Proline
  cct => 'P', ccc => 'P', cca => 'P', ccg => 'P',
  # Threonine
  act => 'T', acc => 'T', aca => 'T', acg => 'T',
  # Alanine
  gct => 'A', gcc => 'A', gca => 'A', gcg => 'A',

  # Tyrosine & Stop
  tat => 'Y', tac => 'Y', taa => '*', tag => '*',
  # Histidine & Glutamine
  cat => 'H', cac => 'H', caa => 'Q', cag => 'Q',
  # Asparagine & Lysine
  aat => 'N', aac => 'N', aaa => 'K', aag => 'K',
  # Aspartate & Glutamate
  gat => 'D', gac => 'D', gaa => 'E', gag => 'E',

  # Cysteine, Tryptophan & Stop
  tgt => 'C', tgc => 'C', tga => '*', tgg => 'W',
  # Arginine
  cgt => 'R', cgc => 'R', cga => 'R', cgg => 'R', aga => 'R', agg => 'R',
  # Glycine
  ggt => 'G', ggc => 'G', gga => 'G', ggg => 'G',
);

# sanity check: should be exactly 64 codon→AA pairs
my $n = scalar keys %c2aa;
die "c2aa map wrong size: found $n pairs (should be 64)\n"
    unless $n == 64;

# build AA→codon groups
my %aa2c;
while(my($cd,$aa)=each%c2aa){
  push @{$aa2c{$aa}}, $cd;
}

# RSCU: observed / (group_total/Ncodons_in_group)
my %RSCU;
while(my($aa,$list)=each %aa2c){
  my $sum=0;
  $sum += $codon{$_} for @$list;
  my $n = @$list;
  next if $aa eq '*' or !$sum;
  for my $cd (@$list){
    $RSCU{$cd} = sprintf("%.2f", $codon{$cd} * $n / $sum);
  }
}

# ENc: from Wright 1990
# F_k = (Σ n_i^2 – N) / (N(N–1))
# ENc = 2 + 9/F2 + 1/F3 + 5/F4 + 3/F6
my %Fk;
for my $aa (qw(P Gly Ala Pro Thr Val Leu Ser Arg Ile Met Tyr His Gln Asn Lys Asp Glu Cys Trp Phe)){
  my $group = $aa2c{$aa} or next;
  my $k = @$group;
  next if $k < 2;
  my $N=0; my $num=0;
  for my $cd (@$group){
    my $n = $codon{$cd}||0;
    $N += $n;
    $num += $n*$n;
  }
  next if $N<2;
  $Fk{$k} ||= [];
  push @{$Fk{$k}}, ($num - $N)/($N*($N-1));
}
# build Fk averages as a proper hash
my %Fk_avg = map {
    my $k   = $_;
    my $arr = $Fk{$k} || [];
    my $sum = 0;
    $sum += $_ for @$arr;
    my $avg = @$arr ? $sum / @$arr : 0;
    $k => sprintf("%.4f", $avg);
} keys %Fk;

# ensure we never divide by zero
for my $k (2,3,4,6) {
    $Fk_avg{$k} //= 1;
}

my $Enc = sprintf("%.2f",
    2
  + 9 / $Fk_avg{2}
  + 1 / $Fk_avg{3}
  + 5 / $Fk_avg{4}
  + 3 / $Fk_avg{6}
);

# — 5) AA composition —
my $prot = join '', map { $c2aa{$_}||'X' } @cods;
my %aa; $aa{$_}++ for split //, $prot;

# — 6) ORF stats —
my $start_ct = $codon{atg}||0;
my $stop_ct  = ($codon{taa}||0)+($codon{tag}||0)+($codon{tga}||0);
my @orf_lens;
for my $frame (0,1,2){
  my $i = $frame;
  while($i < $len - 2){
    # find ATG
    if(substr($seq,$i,3) eq 'atg'){
      for(my $j=$i+3; $j<$len-2; $j+=3){
        my $cd = substr($seq,$j,3);
        if($cd =~ /^(taa|tag|tga)$/){
          push @orf_lens, ($j+3 - $i);
          last;
        }
      }
      $i += 3;
    }
    else { $i++ }
  }
}
my $max_orf = @orf_lens ? (sort{$b<=>$a}@orf_lens)[0]:0;
my $avg_orf = @orf_lens? sprintf("%.1f", eval join '+',@orf_lens/@orf_lens):0;

# — 7) sliding‐window GC% —
my $w = 100;
my @win_gc;
for my $i (0..$len-$w){
  my $sub = substr($seq,$i,$w);
  my $g = ($sub =~ tr/g//)+( $sub =~ tr/c// );
  push @win_gc, sprintf("%d–%d: %.1f%%", $i+1, $i+$w, $g/$w*100);
}

# — 8) 3-mer Shannon entropy —
my %tri;
while($seq =~ /(...)/g){ $tri{$1}++ }
my $total = $len - 2;
my $H = 0;
for my $n (values %tri){
  my $p = $n/$total;
  $H -= $p * log($p)/log(2) if $p>0;
}
$H = sprintf("%.4f", $H);

# — PRINT ALL METRICS —
print $OUT <<"EOF";
INPUT:
  length:    $len
  codons:    $n_codon

NUCLEOTIDE COUNTS & %:
  A=$A  T=$T  G=$G  C=$C
  GC%= $GCpct  AT%= $ATpct
  GC skew= $GCskew  AT skew= $ATskew

DINUCLT COUNT:
EOF
for my $di (sort keys %di) {
  print $OUT sprintf("  %s: %d\n", uc $di, $di{$di});
}

print $OUT "\nCODON COUNTS:\n";
for my $c (sort keys %codon) {
  print $OUT sprintf("  %s: %5d\n", uc $c, $codon{$c});
}

print $OUT "\nRSCU:\n";
for my $c (sort keys %RSCU) {
  print $OUT sprintf("  %s: %5.2f\n", uc $c, $RSCU{$c});
}
print $OUT "\nEffective Number of Codons (ENc): $Enc\n";

print $OUT "\nAMINO-ACID COMPOSITION:\n";
for my $aa (sort keys %aa) {
  my $pct = $n_codon ? sprintf("%.2f", $aa{$aa}/$n_codon*100) : 0;
  print $OUT sprintf("  %s: %5d (%.2f%%)\n", $aa, $aa{$aa}, $pct);
}

print $OUT "\nORF STATISTICS:\n";
print $OUT "  start codons (ATG): $start_ct\n";
print $OUT "  stop  codons (TAA/TAG/TGA): $stop_ct\n";
print $OUT "  ORFs found: " . scalar(@orf_lens) . "\n";
print $OUT "  longest ORF: $max_orf nt\n";
print $OUT "  average ORF: $avg_orf nt\n";

print $OUT "\nSLIDING‐WINDOW GC% (w=100):\n";
print $OUT "  $_\n" for @win_gc;

print $OUT "\n3-MER SHANNON ENTROPY: $H bits\n";
close $OUT;