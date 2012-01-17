use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME                => 'Hashutils',
	AUTHOR              => q{Belden Lyman <belden@shutterstock.com>},
	VERSION_FROM        => 'lib/Hashutils.pm',
	ABSTRACT            => 'Pairwise list manipulators',
	($ExtUtils::MakeMaker::VERSION >= 6.3002
		? ('LICENSE'=> 'perl')
		: ()),
	PL_FILES            => {},
	dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);
