#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Basename qw(dirname);

my $repo_root = File::Spec->rel2abs(File::Spec->catdir(dirname(__FILE__), '..', '..'));
my $script    = File::Spec->catfile($repo_root, 'scripts', 'hydropathy.pl');
my $fixture   = File::Spec->catfile($repo_root, 'tests', 'fixtures', 'test.fasta');
my $plot_out  = File::Spec->catfile($repo_root, 'tests', 'fixtures', 'hydro_plot.txt');
my $sum_out   = File::Spec->catfile($repo_root, 'tests', 'fixtures', 'hydro_summary.txt');

plan tests => 4;

# 1. Script file exists
ok(-f $script, "hydropathy.pl script exists");

# 2. Script passes Perl syntax check
my $syntax = system($^X, '-c', $script, '2>/dev/null');
is($syntax, 0, "hydropathy.pl passes syntax check (perl -c)");

# 3. Script exits with error when called with no arguments
my $no_args = system($^X, $script, '2>/dev/null');
isnt($no_args, 0, "hydropathy.pl exits non-zero with missing arguments");

# 4. Script runs successfully on test fixture
my $rc = system($^X, $script, $fixture, $plot_out, $sum_out);
is($rc, 0, "hydropathy.pl runs successfully on test fixture");

unlink $plot_out if -f $plot_out;
unlink $sum_out  if -f $sum_out;
