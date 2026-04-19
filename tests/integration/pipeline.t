#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Basename qw(dirname);

my $repo_root = File::Spec->rel2abs(File::Spec->catdir(dirname(__FILE__), '..', '..'));

plan tests => 2;

# Check Nextflow is available
my $nf_check = system('nextflow', '-version');
SKIP: {
    skip "Nextflow not available in PATH", 2 unless $nf_check == 0;

    # Run the test profile
    my $old_dir = Cwd::cwd();
    chdir $repo_root;
    my $rc = system('nextflow', 'run', 'main.nf', '-profile', 'test', '--outdir', 'results_test');
    chdir $old_dir;

    is($rc, 0, "nextflow run main.nf -profile test exits with code 0");

    my $results_dir = File::Spec->catdir($repo_root, 'results_test');
    ok(-d $results_dir, "results_test output directory exists after pipeline run");
}
