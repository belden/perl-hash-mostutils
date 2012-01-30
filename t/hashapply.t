#!/usr/bin/perl

use strict;
use warnings;
no warnings 'once';

use Test::More tests => 2;
use Test::Differences qw(eq_or_diff);

use lib '../lib';
use Hashutils qw(hashapply n_apply);

# hashapply
{
	my @orig = (
		1 => 2,
		3 => 4,
		5 => 6,
		7 => 8,
		9 => 10,
	);
	my @got = hashapply { $::a *= 2; $::b *= 3; } @orig;
	eq_or_diff(\@orig, [ 1 .. 10 ]);
	eq_or_diff( \@got, [
		2  => 6,
		6  => 12,
		10 => 18,
		14 => 24,
		18 => 30,
	] );
}
