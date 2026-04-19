#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
# ============================================================
# Script: hydropathy.pl
# Author: Abhinav Mishra <mishraabhinav36@gmail.com>
# Date:   2025
# Copyright (c) 2025 Abhinav Mishra. All rights reserved.
# License: MIT (see LICENSE file in repository root)
# GCP: Perl5 (GNU Coding Practices for Perl5)
# ============================================================
use Carp;

# FASTA in, two outputs
my ($in_fasta, $plot_out, $sum_out) = @ARGV;
croak "Usage: $0 in.fasta H_PLOT.txt H_SUMMARY.txt\n" unless $sum_out;

# Kyte-Doolittle hydropathy (numeric)
my %scale = (
  A=> 1.8,  R=>-4.5, N=>-3.5, D=>-3.5, C=> 2.5,
  Q=>-3.5,  E=>-3.5, G=>-0.4, H=>-3.2, I=> 4.5,
  L=> 3.8,  K=>-3.9, M=> 1.9, F=> 2.8, P=>-1.6,
  S=>-0.8,  T=>-0.7, W=>-0.9, Y=>-1.3, V=> 4.2,

  # handle ambiguity codes:
  B=>-3.5,   # avg(D,N)
  Z=>-3.5,   # avg(E,Q)
  X=> 0.0,   # unknown
  U=> 2.5,   # treat selenocysteine like C
);

#- sub to compute one record's hydropathy values -#
sub process {
    my ($id, $s) = @_;
    return unless defined $id and length $s;

    # per-residue hydropathy array
    my @h = map {
        exists $scale{$_} ? $scale{$_}
        : do { warn "Unknown residue '$_' in $id\n"; 0 }
    } split //, $s;

    # stats
    my $n   = @h;
    my $sum = 0;
    $sum += $_ for @h;
    my $mean = $n ? sprintf("%.3f", $sum/$n) : 0;
    my ($min,$max) = ($h[0], $h[0]);
    $min = $_ < $min ? $_ : $min for @h;
    $max = $_ > $max ? $_ : $max for @h;

    my $plot_line = join("\t",
        $id,
        $s,
        join(' ', map { sprintf("%.1f",$_) } @h),
    ) . "\n";

    my $sum_line = join("\t", $id, $n, $mean, $min, $max) . "\n";

    return ($plot_line, $sum_line);
}

# Slurp FASTA file into records
my @fasta_recs;
{
    open my $IN, '<', $in_fasta or croak $!;
    local $/ = undef;    # slurp entire file at once
    my $content = <$IN>;
    close $IN;
    @fasta_recs = split / \n (?=>) /x, $content;    # split on record boundaries
}

# Parse FASTA and compute hydropathy
my (@plot_lines, @sum_lines);
my ($name, $seq);
for my $rec (@fasta_recs) {
    my @lines = split / \n /x, $rec;    # split record into lines
    for my $line (@lines) {
        if ( $line =~ / ^ > (\S+) /x ) {    # FASTA header
            if ( defined $name ) {
                my ($pl, $sl) = process($name, $seq);
                push @plot_lines, $pl if defined $pl;
                push @sum_lines,  $sl if defined $sl;
            }
            ($name, $seq) = ($1, '');
        }
        else {
            $line =~ s/ \s+ //gx;    # strip whitespace
            $seq .= uc $line;
        }
    }
}
if ( defined $name ) {
    my ($pl, $sl) = process($name, $seq);
    push @plot_lines, $pl if defined $pl;
    push @sum_lines,  $sl if defined $sl;
}

# Write plot file
{
    open my $P, '>', $plot_out or croak $!;
    print $P join("\t", qw(Name Sequence HydropathyValues)), "\n";
    print $P $_ for @plot_lines;
    close $P;
}

# Write summary file
{
    open my $S, '>', $sum_out or croak $!;
    print $S join("\t", qw(Name Length MeanHydropathy MinHydropathy MaxHydropathy)), "\n";
    print $S $_ for @sum_lines;
    close $S;
}

print "Done: details in $plot_out; summary in $sum_out\n";

__END__

=head1 NAME

hydropathy.pl - Calculate residue-level hydropathy profiles from protein FASTA

=head1 SYNOPSIS

  perl hydropathy.pl <in.fasta> <H_PLOT.txt> <H_SUMMARY.txt>

=head1 DESCRIPTION

Calculates Kyte-Doolittle hydropathy values for residues in each FASTA record,
producing a detailed per-sequence values file and a summary statistics table.

=head1 OPTIONS

=over 4

=item B<< <in.fasta> >>

Input protein FASTA file.

=item B<< <H_PLOT.txt> >>

Output file with per-residue hydropathy values.

=item B<< <H_SUMMARY.txt> >>

Output file with per-sequence summary statistics.

=back

=head1 INPUT/OUTPUT

Input:

- Single-record protein FASTA file.

Output:

- Hydropathy detail table.
- Hydropathy summary table.

=head1 AUTHOR

Abhinav Mishra E<lt>mishraabhinav36@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2025 Abhinav Mishra.

Distributed under the BSD 3-Clause License.

=cut
