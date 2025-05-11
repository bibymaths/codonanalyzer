#!/usr/bin/env perl
use strict;
use warnings;

# -------------------------------------------------------------------
# Usage: translate_fasta.pl input.fasta [output.fasta]
# -------------------------------------------------------------------

my ($infile, $outfile) = @ARGV;
die "Usage: $0 input.fasta [output.fasta]\n" unless $infile;
$outfile ||= 'translated.fasta';

# codon→AA lookup (64 codons, stops map to '*')
my %TRANSLATION = (
  # Phe, Leu, Ile, Met, Val, Ser, Pro, Thr, Ala, Tyr, His, Gln,
  TTT=>'F', TTC=>'F', TTA=>'L', TTG=>'L', CTT=>'L', CTC=>'L', CTA=>'L', CTG=>'L',
  ATT=>'I', ATC=>'I', ATA=>'I', ATG=>'M',
  GTT=>'V', GTC=>'V', GTA=>'V', GTG=>'V',
  TCT=>'S', TCC=>'S', TCA=>'S', TCG=>'S', AGT=>'S', AGC=>'S',
  CCT=>'P', CCC=>'P', CCA=>'P', CCG=>'P',
  ACT=>'T', ACC=>'T', ACA=>'T', ACG=>'T',
  GCT=>'A', GCC=>'A', GCA=>'A', GCG=>'A',
  TAT=>'Y', TAC=>'Y', CAT=>'H', CAC=>'H',
  CAA=>'Q', CAG=>'Q', AAT=>'N', AAC=>'N',
  AAA=>'K', AAG=>'K', GAT=>'D', GAC=>'D',
  GAA=>'E', GAG=>'E', TGT=>'C', TGC=>'C',
  TGG=>'W',
  CGT=>'R', CGC=>'R', CGA=>'R', CGG=>'R', AGA=>'R', AGG=>'R',
  GGT=>'G', GGC=>'G', GGA=>'G', GGG=>'G',
  # stops
  TAA=>'', TAG=>'', TGA=>'',
);

open my $IN,  '<', $infile
  or die "Cannot open input '$infile': $!\n";
open my $OUT, '>', $outfile
  or die "Cannot write output '$outfile': $!\n";

# Read one FASTA record at a time
local $/ = "\n>";
while ( my $rec = <$IN> ) {
    chomp $rec;
    $rec =~ s/^>//;                      # remove leading '>'
    my ($header, @lines) = split /\n/, $rec;
    my $id = (split /\s+/, $header)[0];  # take first word as seq ID

    # join sequence lines, strip whitespace & ambiguity
    my $seq = join('', @lines);
    $seq =~ s/\s+//g;     # remove all whitespace
    $seq = uc $seq;       # uppercase
    $seq =~ s/[^ACGT]//g; # drop any non-ACGT letters

    # split into codons (C-level) and translate
    my @codons = unpack("(A3)*", $seq);
    my $protein = join '', map {
        $TRANSLATION{$_} // 'X'   # 'X' for any unexpected codon
    } @codons;

    # write protein FASTA
    print $OUT ">$id\n$protein\n";
}

close $IN;
close $OUT;
print "Translation complete — see '$outfile'\n";
