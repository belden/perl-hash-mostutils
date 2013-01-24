use strict;
use warnings;
package Hash::MostUtils::leach;

my %leaches;

sub new {
	my ($class, %args) = @_;
	my $caller = join ',', (caller(1))[0..3];
	return $leaches{$caller} ||= bless +{
		data => $args{data},
		index => 0,
		ident => $caller,
		n => $args{n},
	}, $class;
}

sub next_set {
	my $self = shift;
	if ($self->{index} > $#{$self->{data}}) {
		delete $leaches{$self->{ident}};
		return ();
	} else {
		my $n = $self->{n};
		$self->{index} += $n;
		return @{$self->{data}}[($self->{index} - $n) .. ($self->{index} - 1)];
	}
};

1;

__END__

=head1 NAME

Hash::MostUtils::leach - an internal module for implementing l(ist)each
