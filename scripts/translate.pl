#!/usr/bin/env perl
use strict;
use warnings;

# Usage: perl translate_fasta.pl input.fasta [output.txt]
my ($infile, $outfile) = @ARGV;
die "Usage: $0 input.fasta [output.txt]\n" unless $infile;
$outfile ||= 'Trans_Prot.txt';

# build translation table once
my %TRANSLATION = (
  map { $_ => 'S' } qw(TCA TCC TCG TCT AGC AGT),
  map { $_ => 'F' } qw(TTC TTT),
  map { $_ => 'L' } qw(TTA TTG CTC CTG CTA CTT),
  map { $_ => 'Y' } qw(TAC TAT),
  map { $_ => ''  } qw(TAA TAG TGA),  # stops become empty
  map { $_ => 'C' } qw(TGC TGT),
  TGG => 'W',
  map { $_ => 'P' } qw(CCA CCC CCG CCT),
  map { $_ => 'H' } qw(CAC CAT),
  map { $_ => 'Q' } qw(CAA CAG),
  map { $_ => 'R' } qw(CGA CGC CGG CGT AGA AGG),
  map { $_ => 'I' } qw(ATA ATC ATT),
  ATG => 'M',
  map { $_ => 'T' } qw(ACA ACC ACG ACT),
  map { $_ => 'N' } qw(AAC AAT),
  map { $_ => 'K' } qw(AAA AAG),
  map { $_ => 'V' } qw(GTA GTC GTG GTT),
  map { $_ => 'A' } qw(GCA GCC GCG GCT),
  map { $_ => 'D' } qw(GAC GAT),
  map { $_ => 'E' } qw(GAA GAG),
  map { $_ => 'G' } qw(GGA GGC GGG GGT),
);

open my $IN,  '<', $infile  or die "Can't open '$infile': $!\n";
open my $OUT, '>', $outfile or die "Can't write '$outfile': $!\n";

local $/ = "\n>";    # fast FASTA record reader
while ( my $record = <$IN> ) {
    chomp $record;
    $record =~ s/^>//;                    # strip leading '>'
    my ($header, @seq_lines) = split /\n/, $record;
    my $id  = (split /\s+/, $header)[0];  # first word is ID
    my $seq = join('', @seq_lines);
    $seq =~ s/\s+//g;                     # drop whitespace
    $seq = uc $seq;                       # uppercase

    # split into codons, translate, join
    my @codons = unpack("(A3)*", $seq);
    my $protein = join '', map {
        exists $TRANSLATION{$_}
          ? $TRANSLATION{$_}
          : (warn "Warning: bad codon '$_' in $id\n", 'X')
    } @codons;

    # output in human‐readable form
    print $OUT ">$id\n$protein\n";
}

close $IN;
close $OUT;

print "Done. Translations written to '$outfile'.\n";
