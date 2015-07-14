#!/bin/env perl

use strict;
use warnings;
no warnings 'once';

use Test::More tests => 2;

use FindBin qw($Bin);
use lib grep { -d } map { "$Bin/$_" } qw(../lib ./lib ./t/lib);
use Hash::MostUtils qw(hashmerge);

# hashmerge
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

  my @merged = hashmerge(@input);
  is_deeply( \@merged, [
    odd  => [1, 3, 5, 7, 9],
    even => [2, 4, 6, 8, 10],
  ], 'hashmerge works' );

  @merged = hashmerge(even => 0, @input);
  is_deeply( \@merged, [
    even => [0, 2, 4, 6, 8, 10],
    odd  => [1, 3, 5, 7, 9],
  ], 'hashmerge preserves relative ordering of inputs' );
}
