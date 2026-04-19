#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Basename qw(dirname);

my $repo_root = File::Spec->rel2abs(File::Spec->catdir(dirname(__FILE__), '..', '..'));
my $script    = File::Spec->catfile($repo_root, 'scripts', 'codon.pl');
my $fixture   = File::Spec->catfile($repo_root, 'tests', 'fixtures', 'test.fasta');
my $outfile   = File::Spec->catfile($repo_root, 'tests', 'fixtures', 'codon_test_out.txt');

plan tests => 4;

# 1. Script file exists
ok(-f $script, "codon.pl script exists");

# 2. Script passes Perl syntax check
my $syntax = system("$^X -c \Q$script\E 2>/dev/null");
is($syntax, 0, "codon.pl passes syntax check (perl -c)");

# 3. Script exits with error when called with no arguments
my $no_args = system("$^X \Q$script\E 2>/dev/null");
isnt($no_args, 0, "codon.pl exits non-zero with missing arguments");

# 4. Script runs successfully on test fixture
my $rc = system($^X, $script, $fixture, $outfile);
is($rc, 0, "codon.pl runs successfully on test fixture");

unlink $outfile if -f $outfile;
