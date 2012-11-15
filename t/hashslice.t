#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 4;
use Test::Exception;

use lib grep { -d } qw(../lib ./lib);
use Shutterstock::Test qw(deep_ok);
use Hash::MostUtils qw(hash_slice_of hash_slice_by);

{
	package stub;
	sub new { shift; return bless +{@_} }
	sub baz { shift->{_baz} }
	sub DESTROY {}
	sub AUTOLOAD {
		my $self = shift;
		my ($method) = our $AUTOLOAD =~ m{.*:(.*)};
		return $self->{$method};
	}
}

{
	package somewhere;
	sub new { shift; bless +{@_} }
}

my %common = (
  foo => 'shippen-superabomination',
  bar => 'speron-prevocational',
);
my $stub = stub->new(
	%common,
  _baz => 211,
);
deep_ok( +{hash_slice_of($stub, qw(foo bar baz))}, {
	%common,
	baz => undef,
}, 'hash_slice_of looks inside of hash references' );
ok( ! exists $stub->{baz}, "We didn't autovivify missing keys into the original reference" );

deep_ok( +{hash_slice_by($stub, qw(foo bar baz))}, {
	%common,
	baz => 211,
}, 'hash_slice_by calls methods on the given object' );


my $thing = somewhere->new(joola => 'Quickel');
dies_ok {
	hash_slice_by($thing, qw(Oscan));
	1;
} 'hash_slice_by raises assertions when you try to call methods that don\'t exist';
