#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 1;

use FindBin qw($Bin);
use lib grep { -d } map { "$Bin/$_" } qw(../lib ./lib ./t/lib);
use Hash::MostUtils qw(reindex);

use Test::Easy qw(deep_ok);

{
  my @start = (1..5);
  my @reindex = reindex { map { $_ => $_ + 1 } 0..$#start } @start;
  deep_ok( \@reindex, [undef, 1..5] );
}
