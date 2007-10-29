package [% v.namespace %];

###########################################################################
# [% v.namespace %]
# [% v.name %]
# $Id: NAMESPACE.pm,v 1.3 2006/11/29 02:40:22 mgrimes Exp $
#
# [% v.abstract %]
# Copyright (c) [% v.year %] [% v.name %] ([% v.email %]).
# All rights reserved. This program is free software; you can redistribute
# it and/or modify it under the same terms as Perl itself.
#
# Formatted with tabstops at 4
#
# Parts of this package were inspired by:
#   -- Give credit if due --
# Thanks!
#
###########################################################################

use strict;
use warnings;

use Carp;
use Hash::Util qw(lock_keys);	# Lock a hash so no new keys can be added

our $VERSION = '0.01';

# #########################################################
#	Fields contains all of the objects data which can be
#	set/retreived by an accessor methods
# #########################################################

my %fields = (		# List of all the fields which will have accessors
	'name'		=> undef,		# the name 
);

use base qw(Class::Accessor::Fast);
__PACKAGE__->mk_accessors( keys %fields );


sub new {
	my $that  = shift;
	my $class = ref($that) || $that;	# Enables use to call $instance->new()
	my $self  = {
		'_private' 	=> 0,	# Private variables
		%fields,
	};
	bless $self, $class;

	# Lock the $self hashref, so we don't accidentally add a key!
	# TODO: how does this impact inheritance?
	lock_keys( %$self );

	return $self;
}

1;

__END__

# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

[% v.namespace %] - [% abstract %]

=head1 SYNOPSIS

  use [% v.namespace %];
  blah blah blah

=head1 DESCRIPTION

Stub documentation for [% v.namespace %]. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head2 EXPORT

None by default.

=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

[% v.name %], E<lt>[% email %]<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by mgrimes

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
