#!/usr/bin/perl
# Questa batch flow. This script is a thin wrapper of scripts/uartvip.py, kept for the old command:
#
#   ./run_qsim.pl <pattern name>      build (once) and run one pattern, e.g. ./run_qsim.pl trialPat
#   ./run_qsim.pl MERGE_COVERAGE      merge the coverage databases and write the HTML report
#
# Differences from the previous version:
#  - no source file is copied or modified; every pattern in ../pat is a uvm_test (test_<pattern name>)
#  - the exit status is 0 only when the test printed "** TEST PASSED **"
#  - no tool path is written here: set QUESTA_HOME (directory with vsim/vlog) or put them on PATH,
#    and UVM_SRC (the uvm src directory of Questa, or of Accellera UVM)
# Prefer:  make build run SIM=questa TEST=<pattern name>
use strict;
use warnings;
use FindBin qw($Bin);

my $arg = shift @ARGV;
die "usage: run_qsim.pl <pattern name> | MERGE_COVERAGE\n" unless defined $arg;

my $py   = $ENV{PY} || "python3";
my $tool = "$Bin/../scripts/uartvip.py";
my @base = ($py, $tool, "--sim", "questa", "--cov");

sub run { my $rc = system(@_); return $rc >> 8; }

if ($arg eq "MERGE_COVERAGE") {
    exit run(@base, "cov");
}
my $exe_ok = run(@base, "build");
exit $exe_ok if $exe_ok;
exit run(@base, "run", "--test", $arg);
