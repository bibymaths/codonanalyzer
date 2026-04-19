#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
# ============================================================
# Script: longORF.pl
# Author: Abhinav Mishra <mishraabhinav36@gmail.com>
# Date:   2025
# Copyright (c) 2025 Abhinav Mishra. All rights reserved.
# License: MIT (see LICENSE file in repository root)
# GCP: Perl5 (GNU Coding Practices for Perl5)
# ============================================================
use Carp;

if ( @ARGV < 2 ) {
    croak "Usage: $0 <in.fasta> <out.table> [whole]\n";
}

my ($in_fasta, $out_table, $mode) = @ARGV;
my $whole_seq = ($mode && $mode eq 'whole') ? 1 : 0;

# standard codon->AA table (no ambiguity codes)
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

# pre-compile stop codon test
my %is_stop = map { $_ => 1 } qw(TAA TAG TGA);

# ---- sub: scan all three frames and return best ORF indices ----
sub _find_best_orf {
    my ($codons_ref, $nc) = @_;
    my ($best_len, $best_frame, $best_i, $best_j) = (0) x 4;
    for my $frame (0..2) {
        my $in_orf  = 0;
        my $start_i = 0;
        for (my $i = $frame; $i < $nc; $i++) {
            my $cod = $codons_ref->[$i] or next;
            if (!$in_orf && $cod eq 'ATG') {
                $in_orf  = 1;
                $start_i = $i;
            }
            elsif ($in_orf && $is_stop{$cod}) {
                my $length = ($i - $start_i + 1) * 3;
                if ($length > $best_len) {
                    ($best_len, $best_frame, $best_i, $best_j)
                      = ($length, $frame, $start_i, $i);
                }
                $in_orf = 0;    # reset for next ORF search
            }
        }
    }
    return ($best_len, $best_frame, $best_i, $best_j);
}

# Slurp FASTA input into raw records
my @raw_recs;
{
    open my $IN, '<', $in_fasta or croak "Can't read $in_fasta: $!";
    local $/ = undef;    # slurp entire file, scoped to this block
    my $content = <$IN>;
    close $IN;
    @raw_recs = split / \n (?=>) /x, $content;    # split on FASTA record boundaries
}

# Process each FASTA record, collecting table and FASTA output
my (@table_rows, @fasta_rows);
for my $rec (@raw_recs) {
    $rec =~ s/ ^ > //x;          # remove leading >
    my ($hdr, @lines) = split / \n /x, $rec;
    my $seq = join '', @lines;
    $seq =~ tr/ \r\n\t//d;       # strip whitespace
    $seq = uc $seq;               # uppercase

    # optionally get reverse complement
    my $rc = reverse $seq;
    $rc =~ tr/ACGT/TGCA/;

    # process each strand (+1 => $seq, -1 => $rc)
    for my $strand ( +1, -1 ) {
        my $sseq    = ($strand > 0 ? $seq : $rc);
        my @codons  = unpack("(A3)*", $sseq);
        my $nc      = @codons;

        my ($best_len, $best_frame, $best_i, $best_j) = _find_best_orf(\@codons, $nc);
        next unless $best_len;    # no ORF found

        # extract nt & aa sequences
        my $ntseq = join '', @codons[$best_i .. $best_j];
        my $aaseq = '';
        $aaseq .= ($tt{$_}||'X') for unpack("(A3)*", $ntseq);

        # compute padded aa-length string
        my $aalen = length($aaseq);
        my $pad   = sprintf("%03d", $aalen);

        push @table_rows, sprintf("%s\t%ddb\t%s%s aa\t%d..%d\t%s\t%s\n",
          $hdr,
          $best_len,
          $pad,
          $aalen,
          ($best_frame + 1),
          ($best_j - $best_frame) * 3 + 1,
          $ntseq,
          $aaseq);

        my $outseq = $whole_seq ? $sseq : $ntseq;
        push @fasta_rows, sprintf(">%s|%ddb|%s%s aa|%d..%d\n%s\n",
          $hdr,
          $best_len,
          $pad,
          $aalen,
          ($best_frame + 1),
          ($best_j - $best_frame) * 3 + 1,
          $outseq);
    }
}

# Write table output
{
    open my $OUT, '>', $out_table or croak "Can't write $out_table: $!";
    print $OUT $_ for @table_rows;
    close $OUT;
}

# Write FASTA output
{
    open my $OFA, '>', "$out_table.fasta"
      or croak "Can't write $out_table.fasta: $!";
    print $OFA $_ for @fasta_rows;
    close $OFA;
}

__END__

=head1 NAME

longORF.pl - Detect longest open reading frames from a DNA FASTA record

=head1 SYNOPSIS

  perl longORF.pl <in.fasta> <out.table> [whole]

=head1 DESCRIPTION

Scans forward and reverse-complement strands for canonical ORFs, reports the
longest ORF per strand/frame context, and writes both tabular and FASTA output.

=head1 OPTIONS

=over 4

=item B<< <in.fasta> >>

Input DNA FASTA file.

=item B<< <out.table> >>

Output ORF table file; FASTA output is written as C<< <out.table>.fasta >>.

=item B<[whole]>

Optional literal C<whole> to emit the full sequence rather than only ORF nt
sequence in FASTA output.

=back

=head1 INPUT/OUTPUT

Input:

- Single-record DNA FASTA file.

Output:

- ORF summary table.
- ORF FASTA file.

=head1 AUTHOR

Abhinav Mishra E<lt>mishraabhinav36@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2025 Abhinav Mishra.

Distributed under the BSD 3-Clause License.

=cut
