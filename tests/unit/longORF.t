#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Basename qw(dirname);

my $repo_root = File::Spec->rel2abs(File::Spec->catdir(dirname(__FILE__), '..', '..'));
my $script    = File::Spec->catfile($repo_root, 'scripts', 'longORF.pl');
my $fixture   = File::Spec->catfile($repo_root, 'tests', 'fixtures', 'test.fasta');
my $outfile   = File::Spec->catfile($repo_root, 'tests', 'fixtures', 'longorf_test_out.txt');

plan tests => 4;

# 1. Script file exists
ok(-f $script, "longORF.pl script exists");

# 2. Script passes Perl syntax check
my $syntax = system($^X, '-c', $script, '2>/dev/null');
is($syntax, 0, "longORF.pl passes syntax check (perl -c)");

# 3. Script exits with error when called with no arguments
my $no_args = system($^X, $script, '2>/dev/null');
isnt($no_args, 0, "longORF.pl exits non-zero with missing arguments");

# 4. Script runs successfully on test fixture
my $rc = system($^X, $script, $fixture, $outfile);
is($rc, 0, "longORF.pl runs successfully on test fixture");

unlink $outfile if -f $outfile;
unlink "${outfile}.fasta" if -f "${outfile}.fasta";
