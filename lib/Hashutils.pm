package Hashutils;

use strict;
use warnings;

use base qw(Exporter);

our @EXPORT_OK = qw(hashmap hashgrep n_map n_grep lvalues lkeys);
our $VERSION = 0.01;

=head1 NAME

Hashutils - A collection of tools for operating pairwise on lists.

=head1 SYNOPSIS

=over 4

  my @found_and_transformed =
    hashmap { uc($b) => 100 + $a }
    hashgrep { $a < 100 && $b =~ /[aeiou]/i } (
      1 => 'cwm',
      2 => 'apple',
      100 => 'cherimoya',
    );


=cut

=head1 EXPORTS

By default, none. On request, C<hashmap>, C<hashgrep>, C<n_map>, C<n_grep>, C<lkeys>, C<lvalues>.

=cut

sub _n_collect($) {
	my ($n) = @_;
	return sub(&@) {
		my $collector = shift;
		my $code = shift;
		if (@_ % $n != 0) {
			require Carp;
			Carp::confess "your input is insane: can't evenly slice " . @_ . " elements into $n-sized chunks\n";
		}

		# reserve some namespace back in the callpackage
		my @n = ('a' .. 'z');

		# stash old values back in callpackage *and* in main. If called from main::, this comes down to:
		#   local ${'main::a'}, ${'main::b'}, ${'main::c'}
		# when $n is 3.
		my $caller = caller;
		no strict 'refs';
		foreach ((@n[ 0 .. $n-1 ])) {
      local ${"$caller\::$_"};
      local ${"::$_"};
    }

		my @out;
		while (my @chunk = splice @_, 0, $n) {  # build up each set...
			foreach (0 .. $#chunk) {
				# ...assign values from @_ back to localized variables in $caller *and* in 'main::'.
				# Aliasing in main::  allows you to refer to variables $c and onwards as $::c.
				# Aliasing in $caller allows you to refer to variables $c and onwards as $whatever::package::c.
        ${"::$n[$_]"} = ${"$caller\::$n[$_]"} = $chunk[$_];
      }
			push @out, $collector->($code, @chunk);             # ...and apply $code.
		}

		return @out;
	};
}


=head2 n_map N, CODEREF, LIST

Apply CODEREF to LIST, operating in N-sized chunks. Within the context of CODEREF, values of LIST
will be selected and aliased. Given N of 5, variable names would be $a, $b, $c, $d, and $e. In order
to prevent 'strict refs' from complaining, you should write CODEREF to refer to $::a, $::b, $::c,
$::d, and $::e (for N == 5).

Actually, that's a lie: it's only $c .. $e that would need to be $::c, $::d, $::e. $a and $b are
magical to Perl, but the shift from $a and $b to $::c here looks pretty bad:

=over 4

  my @transformed = n_map(
    3,
    sub { "$a, $b $::c!\n" },
    qw(goodnight sweet prince goodbye cruel world),
  );

=back

LIST must be evenly divisible by N.

=cut
sub n_map ($&@) {
	# Usually I don't mutate @_. Here I deliberately modify @_ for the upcoming non-obvious goto-&NAME.
	my $n = shift;
	my $collector = sub { return $_[0]->() };
	unshift @_, $collector;

	# Using a "safe goto" allows n_map() to remove itself from the callstack, which allows _n_collect()
	# to see the correct caller.
	#
	# 'perldoc -f goto' for why this is a safe goto.
	goto &{_n_collect($n)};
}

=head2 hashmap BLOCK, LIST

C<hashmap> is simply a prototyped alias for n_map(2, CODEREF, LIST), so all of the documentation to
C<n_map> applies here.

"keys" (even-positioned items in LIST) are available as $a. "values" (odd-positioned items in LIST)
are available as $b.

Like perl's built-in C<map>, this function maintains the order of LIST.

=cut
*hashmap = sub(&@) { unshift @_, 2; goto &n_map };

=head2 n_grep N, CODEREF, LIST

Apply CODEREF to LIST, operating in N-sized chunks. Within the context of CODEREF, values of LIST
will be selected and aliased. Given N of 5, variable names would be $a, $b, $c, $d, and $e. In order
to prevent 'strict refs' from complaining, you should write CODEREF to refer to $::a, $::b, $::c,
$::d, and $::e (for N == 5).

Actually, that's a lie: it's only $c .. $e that would need to be $::c, $::d, $::e. $a and $b are
magical to Perl, but the shift from $a and $b to $::c here looks pretty bad:

=over 4

  my @found = n_grep(
    3,
    sub { $a =~ /good/ && $::c =~ /prince/ },
    qw(goodnight sweet prince goodbye cruel world),
  );

  # @found = qw(goodnight sweet prince);

=back

LIST must be evenly divisible by N.

=cut
sub n_grep ($&@) {
	my $n = shift;

	# the comments in n_map() apply here as well.

	my $collector = sub {
		my ($code, @vals) = @_;
		return $code->() ? @vals : ();
	};
	unshift @_, $collector;

	goto &{_n_collect($n)};
}

=head2 hashgrep BLOCK, LIST

C<hashgrep> is simply a prototyped alias for n_grep(2, CODEREF, LIST), so all of the documentation
to C<n_grep> applies here.

"keys" (even-positioned items in LIST) are available as $a. "values" (odd-positioned items in LIST)
are available as $b.

Like perl's built-in C<grep>, this function maintains the order of LIST.

=cut
# hashgrep BLOCK, LIST is a convenient alias for Hashutils::n_grep(2, CODEREF, LIST);
*hashgrep = sub(&@) { unshift @_, 2; goto &n_grep };

=head2 lkeys LIST

Return the "keys" of LIST. perl's built-in keys() function only operates on hashes; lkeys() offers
the same functionality for lists.

=cut
# Using $| as a piddle; 'perldoc perlvar'.
sub lkeys { local $|; return grep { $|-- == 0 } @_ }

=head2 lvalues LIST

Return the "values" of LIST. perl's built-in values() function only operates on hashes; lvalues() offers
the same functionality for lists.

=cut
# 'perldoc perlvar': decrementing $| flips it between 0 and 1.
sub lvalues { local $|; return grep { $|-- == 1 } @_ }

1;

__END__

=head1 AUTHOR

Belden Lyman <belden@shutterstock.com>

=head1 ACKNOWLEDGEMENTS

The names and behaviors of 'hashmap', 'hashgrep', 'lkeys', and 'lvalues' were initially developed at
AirWave Wireless. I've re-implemented them in-the-raw here.
