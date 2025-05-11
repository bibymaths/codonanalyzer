#!/usr/bin/env perl
use strict;
use warnings;

die "Usage: $0 <in.fasta> <out.table> [whole]\n"
  unless @ARGV >= 2;

my ($in_fasta, $out_table, $mode) = @ARGV;
my $whole_seq = ($mode && $mode eq 'whole') ? 1 : 0;

open my $IN,  '<', $in_fasta   or die "Can't read $in_fasta: $!";
open my $OUT, '>', $out_table  or die "Can't write $out_table: $!";
open my $OFA, '>', "$out_table.fasta"
  or die "Can't write $out_table.fasta: $!";

# standard codon→AA table (no ambiguity codes)
my %tt = (
  map { $_ => 'F' } qw(TTT TTC),
  map { $_ => 'L' } qw(TTA TTG CTT CTC CTA CTG),
  map { $_ => 'I' } qw(ATT ATC ATA),
  ATG => 'M',
  map { $_ => 'V' } qw(GTT GTC GTA GTG),
  map { $_ => 'S' } qw(TCT TCC TCA TCG AGT AGC),
  map { $_ => 'P' } qw(CCT CCC CCA CCG),
  map { $_ => 'T' } qw(ACT ACC ACA ACG),
  map { $_ => 'A' } qw(GCT GCC GCA GCG),
  map { $_ => 'Y' } qw(TAT TAC),
  map { $_ => 'H' } qw(CAT CAC),
  map { $_ => 'Q' } qw(CAA CAG),
  map { $_ => 'N' } qw(AAT AAC),
  map { $_ => 'K' } qw(AAA AAG),
  map { $_ => 'D' } qw(GAT GAC),
  map { $_ => 'E' } qw(GAA GAG),
  TGT => 'C', TGC => 'C',
  TGG => 'W',
  map { $_ => 'R' } qw(CGT CGC CGA CGG AGA AGG),
  map { $_ => 'G' } qw(GGT GGC GGA GGG),
  map { $_ => '*' } qw(TAA TAG TGA),
);

# pre‐compile stop codon test
my %is_stop = map { $_=>1 } qw(TAA TAG TGA);

$/ = "\n>";   # read one FASTA record at a time
while ( my $rec = <$IN> ) {
    chomp $rec;
    $rec =~ s/^>//;          # remove leading >
    my ($hdr, @lines) = split /\n/, $rec;
    my $seq = join '', @lines;
    $seq =~ tr/ \r\n\t//d;    # strip whitespace
    $seq = uc $seq;           # uppercase

    # optionally get reverse complement
    my $rc = reverse $seq;
    $rc =~ tr/ACGT/TGCA/;

    # process each strand (+1 => $seq, -1 => $rc)
    for my $strand ( +1, -1 ) {
        my $sseq = ($strand > 0 ? $seq : $rc);
        # track best ORF
        my ($best_len, $best_frame, $best_i, $best_j) = (0) x 4;

        # split into codons once
        my @codons = unpack("(A3)*", $sseq);
        my $nc = @codons;

        # scan frames 0,1,2
        for my $frame (0..2) {
            my $in_orf = 0;
            my $start_i;

            for (my $i = $frame; $i < $nc; $i++) {
                my $cod = $codons[$i] or next;

                if (!$in_orf && $cod eq 'ATG') {
                    $in_orf   = 1;
                    $start_i  = $i;
                }
                elsif ($in_orf && $is_stop{$cod}) {
                    my $length = ($i - $start_i + 1) * 3;
                    if ($length > $best_len) {
                        ($best_len, $best_frame, $best_i, $best_j)
                          = ($length, $frame, $start_i, $i);
                    }
                    $in_orf = 0;    # reset for next
                }
            }
        }

        next unless $best_len;  # no ORF found

        # extract nt & aa sequences
        my $ntseq = join '', @codons[$best_i .. $best_j];
        my $aaseq = '';
        $aaseq .= ($tt{$_}||'X') for unpack("(A3)*", $ntseq);

        # compute padded aa‐length string
        my $aalen = length($aaseq);
        my $pad   = sprintf("%03d", $aalen);

        # write table line
        printf $OUT "%s\t%ddb\t%s%s aa\t%d..%d\t%s\t%s\n",
          $hdr,
          $best_len,
          $pad,
          $aalen,
          ($best_frame + 1),
          ($best_j - $best_frame) * 3 + 1,
          $ntseq,
          $aaseq;

        # write FASTA line
        my $outseq = $whole_seq ? $sseq : $ntseq;
        printf $OFA  ">%s|%ddb|%s%s aa|%d..%d\n%s\n",
          $hdr,
          $best_len,
          $pad,
          $aalen,
          ($best_frame + 1),
          ($best_j - $best_frame) * 3 + 1,
          $outseq;
    }
}
close $IN;
close $OUT;
close $OFA;