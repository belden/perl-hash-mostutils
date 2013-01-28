use strict;
use warnings;
package Hash::MostUtils;
use base qw(Exporter);

use Carp qw(confess);
use Hash::MostUtils::leach qw(n_each leach);

our @EXPORT_OK = qw(
  lvalues
  lkeys
	leach
  hash_slice_of
  hash_slice_by
  hashmap
  hashgrep
  hashapply
	n_each
  n_map
  n_grep
  n_apply
);
our $VERSION = 0.04;

sub _n_collect($) {
	my ($n) = @_;
	return sub(&@) {
		my $collector = shift;
		my $code = shift;
		if (@_ % $n != 0) {
			confess("your input is insane: can't evenly slice " . @_ . " elements into $n-sized chunks\n");
		}

		# these'll reserve some namespace back in the callpackage
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
			my @aliases;
			foreach (0 .. $#chunk) {
				# ...assign values from @_ back to localized variables in $caller *and* in 'main::'.
				# Aliasing in main::  allows you to refer to variables $c and onwards as $::c.
				# Aliasing in $caller allows you to refer to variables $c and onwards as $whatever::package::c.
				${"::$n[$_]"} = ${"$caller\::$n[$_]"} = $chunk[$_];

				# Keep a reference to $::a (etc.) and pass them in to the $collector; this allows $code to mutate
				# $::a (etc) and signal the changed values back to $collector.
				push @aliases, \${"::$n[$_]"};
			}
			push @out, $collector->($code, \@chunk, \@aliases);             # ...and apply $code.
		}

		return @out;
	};
}

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

*hashmap = sub(&@) { unshift @_, 2; goto &n_map };

sub n_grep ($&@) {
	my $n = shift;

	# the comments in n_map() apply here as well.

	my $collector = sub {
		my ($code, $vals, $aliases) = @_;
		return $code->() ? @$vals : ();
	};
	unshift @_, $collector;

	goto &{_n_collect($n)};
}

sub n_apply {
	my $n = shift;
	my $collector = sub {
		my ($code, $vals, $aliases) = @_;
		$code->();
		return map { $$_ } @$aliases;
	};
	unshift @_, $collector;

	goto &{_n_collect($n)};
}

# hashgrep BLOCK, LIST is a convenient alias for Hashutils::n_grep(2, CODEREF, LIST);
*hashgrep = sub(&@) { unshift @_, 2; goto &n_grep };

# hashapply BLOCK, LIST is a convenient alias for Hashutils::n_apply(2, CODEREF, LIST);
*hashapply = sub (&@) { unshift @_, 2; goto &n_apply };

# decrementing $| flips it between 0 and 1
sub lkeys   { local $|; return grep { $|-- == 0 } @_ }
sub lvalues { local $|; return grep { $|-- == 1 } @_ }

sub hash_slice_of {
	my ($ref, @keys) = @_;
	return map { ($_ => $ref->{$_}) } @keys;
}

sub hash_slice_by {
	my ($obj, @methods) = @_;
	return map { ($_ => $obj->$_) } @methods;
}

1;

__END__

=head1 NAME

Hash::MostUtils - Yet another collection of tools for operating pairwise on lists.

=head1 SYNOPSIS

=over 4

  my @found_and_transformed =
      hashmap { uc($b) => 100 + $a }
      hashgrep { $a < 100 && $b =~ /[aeiou]/i } (
          1 => 'cwm',
          2 => 'apple',
          100 => 'cherimoya',
      );

  my @keys = lkeys @found_and_transformed;
  my @vals = lvalues @found_and_transformed;
  foreach my $key (@keys) {
      my $value = shift @vals;
      print "$key => $val\n";
  }

=head1 EXPORTS

By default, none. On request, any of the following:

  lvalues
  lkeys
  leach
  hash_slice_of
  hash_slice_by
  hashmap
  hashgrep
  hashapply
  n_each
  n_map
  n_grep
  n_apply

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

=head2 hashmap BLOCK, LIST

C<hashmap> is simply a prototyped alias for n_map(2, CODEREF, LIST), so all of the documentation to
C<n_map> applies here.

"keys" (even-positioned items in LIST) are available as $a. "values" (odd-positioned items in LIST)
are available as $b.

Like perl's built-in C<map>, this function maintains the order of LIST.

=head2 n_grep N, CODEREF, LIST

Find items in LIST that match CODEREF, operating in N-sized chunks. Within the context of CODEREF, values
of LIST will be selected and aliased. Given N of 5, variable names would be $a, $b, $c, $d, and $e. In
order to prevent 'strict refs' from complaining, you should write CODEREF to refer to $::a, $::b, $::c,
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

=head2 n_apply N, CODEREF, LIST

Apply CODEREF to LIST, operating in N-sized chunks. See the discussion of C<hashapply>. See also
variable names as discussed in C<n_map> and C<n_grep>.

=head2 hashgrep BLOCK, LIST

C<hashgrep> is simply a prototyped alias for n_grep(2, CODEREF, LIST), so all of the documentation
to C<n_grep> applies here.

"keys" (even-positioned items in LIST) are available as $a. "values" (odd-positioned items in LIST)
are available as $b.

Like perl's built-in C<grep>, this function maintains the order of LIST.

=head2 hashapply BLOCK, LIST

Apply BLOCK of code to LIST. apply can be written as map:

=over 4

my @words = qw(apple banana cherimoya);
my @clean1 = map { tr/aeiou//d; $_ } @words;  # @clean1 = @words = qw(ppl bnn chrmy);

@words = qw(apple banana cherimoya);
my @clean2 = apply { tr/aeiou//d } @words;    # @clean2 = qw(ppl bnn chrmy); @words = qw(apple banana cherimoya);

=back

Note that C<apply> does not transform the original data, whereas C<map> does.

Note that C<apply> does not need to explicitly return $_, whereas C<map> does.

C<hashapply> works similar to C<apply> except it processes lists pairwise. Like the other C<hash...> functions,
this maintains the original order of LIST. Like C<apply>, C<hashapply> will not transform the original LIST.

=head2 lkeys LIST

Return the "keys" of LIST. perl's built-in keys() function only operates on hashes; lkeys() offers
the same functionality for lists.

=head2 lvalues LIST

Return the "values" of LIST. perl's built-in values() function only operates on hashes; lvalues() offers
the same functionality for lists.

=head2 hash_slice_of HASHREF, LIST

Looks into a hash and extracts the values of the keys named in LIST.
If a key in LIST is not present in HASHREF, returns undefined.

=head2 hash_slice_by OBJECT, LIST

Calls the methods named in LIST on OBJECT and returns a hash of the results.
(If a method in LIST does not exist on OBJECT, you will get an assertion.)

=head1 ACKNOWLEDGEMENTS

The names and behaviors of most of these functions were initially
developed at AirWave Wireless, Inc. I've re-implemented them here.


=head1 COPYRIGHT AND LICENSE

    (c) 2013 by Belden Lyman

This library is free software: you may redistribute it and/or modify it under the same terms as Perl
itself; either Perl version 5.8.8 or, at your option, any later version of Perl 5 you may have
available.
