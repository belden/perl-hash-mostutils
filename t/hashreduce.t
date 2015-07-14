#!/bin/env perl

use strict;
use warnings;
no warnings 'once';

use Test::More tests => 2;

use FindBin qw($Bin);
use lib grep { -d } map { "$Bin/$_" } qw(../lib ./lib ./t/lib);
use Hash::MostUtils qw(hashreduce);

# hashreduce
#
# (Like other 'hash_*' functions, we actually test with an array
# as the input rather than a hash in order to show that the
# function under test does not change the relative ordering.
# Relative ordering might be changed if this function used a
# hash internally for tracking its output.)
{
  my @input = (
   odd  => 1,
   even => 2,
   odd  => 3,
   even => 4,
   odd  => 5,
   even => 6,
   odd  => 7,
   even => 8,
   odd  => 9,
   even => 10,
  );

  my @reduced = hashreduce { $a + $b } @input;
  is_deeply( \@reduced, [
    odd  => 1 + 3 + 5 + 7 + 9,
    even => 2 + 4 + 6 + 8 + 10,
  ], 'hashreduce works' );

  @reduced = hashreduce { $a + $b } (even => 0, @input);
  is_deeply( \@reduced, [
    even => 2 + 4 + 6 + 8 + 10,
    odd  => 1 + 3 + 5 + 7 + 9,
  ], 'hashreduce preserves relative ordering of inputs' );
}
