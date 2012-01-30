use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME                => 'Hash::MostUtils',
	AUTHOR              => q{Belden Lyman <belden@shutterstock.com>},
	VERSION_FROM        => 'lib/Hash/MostUtils.pm',
	ABSTRACT            => 'Pairwise list manipulators',
	($ExtUtils::MakeMaker::VERSION >= 6.3002
		? ('LICENSE'=> 'perl')
		: ()),
	PL_FILES            => {},
	dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);
