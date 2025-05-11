#!/usr/bin/env perl
use strict;
use warnings;

# FASTA in, two outputs
my ($in_fasta, $plot_out, $sum_out) = @ARGV;
die "Usage: $0 in.fasta H_PLOT.txt H_SUMMARY.txt\n" unless $sum_out;

open my $IN,  '<', $in_fasta or die $!;
open my $P,   '>', $plot_out  or die $!;
open my $S,   '>', $sum_out   or die $!;

# Kyte–Doolittle hydropathy (numeric)
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

# write headers
print $P join("\t", qw(Name Sequence HydropathyValues)), "\n";
print $S join("\t", qw(Name Length MeanHydropathy MinHydropathy MaxHydropathy)), "\n";

# parse FASTA
my ($name, $seq);
while (<$IN>) {
    chomp;
    if (/^>(\S+)/) {
        process($name,$seq) if defined $name;
        ($name, $seq) = ($1, '');
    }
    else {
        s/\s+//g;
        $seq .= uc $_;
    }
}
process($name,$seq) if defined $name;

close $_ for ($IN,$P,$S);
print "Done: details in $plot_out; summary in $sum_out\n";

#— sub to compute & write one record —#
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

    # write plot file
    print $P join("\t",
        $id,
        $s,
        join(' ', map { sprintf("%.1f",$_) } @h),
    ), "\n";

    # write summary file
    print $S join("\t", $id, $n, $mean, $min, $max), "\n";
}
