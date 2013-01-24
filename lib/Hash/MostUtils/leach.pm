use strict;
use warnings;
package Hash::MostUtils::leach;
use base qw(Exporter);

BEGIN {
	if ($] >= 5.013) {
		require Hash::MostUtils::leach::v5_13;
		Hash::MostUtils::leach::v5_13->import;
	} else {
		require Hash::MostUtils::leach::v5_08;
		Hash::MostUtils::leach::v5_08->import;
	}
}

our @EXPORT = qw(leach n_each);

{
	my %end;

	# n-ary each for lists
	sub _n_each {
		my $n = shift;
		my $data = shift;

		my $ident = "$data";

		return () if $#{$data} < ($end{$ident} || 0);

		$end{$ident} += $n;
		return @{$data}[$end{$ident} - $n .. $end{$ident} - 1];
	}
}

1;
