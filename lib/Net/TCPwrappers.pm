#
# $Id: TCPwrappers.pm 151 2004-12-26 22:35:29Z james $
#

=head1 NAME

Net::TCPwrappers - Perl interface to tcp_wrappers.

=head1 SYNOPSIS

  use Net::TCPwrappers qw(RQ_DAEMON RQ_FILE request_init fromhost hosts_access);
  ...
  my $progname = 'yadd';
  while (accept(CLIENT, SERVER)) {
    my $req = request_init(RQ_DAEMON, $progname, RQ_FILE, fileno(CLIENT));
    fromhost($req);
    if (!hosts_access($req)) {
      # unauthorized access.
      ...
    }
    else {
      # service connecting client.
      ...
    }
  }

=cut

package Net::TCPwrappers;
use base 'Exporter';

require 5.006_001;

use strict;
use warnings;

use Carp;
use ExtUtils::Constant;
use XSLoader;

our $VERSION = '1.10';

our @EXPORT      = ();
our %EXPORT_TAGS = (
    constants => [ qw|
        RQ_CLIENT_ADDR
        RQ_CLIENT_NAME
        RQ_CLIENT_SIN
        RQ_DAEMON
        RQ_FILE
        RQ_SERVER_ADDR
        RQ_SERVER_NAME
        RQ_SERVER_SIN
        RQ_USER
    | ],
    functions => [ qw|
        request_init
        request_set
        fromhost
        hosts_access
        hosts_ctl
    | ],
);
{
    my %seen;
    push @{$EXPORT_TAGS{all}},
    grep {!$seen{$_}++} @{$EXPORT_TAGS{$_}} foreach keys %EXPORT_TAGS;
}
                                                     
Exporter::export_ok_tags( 'all' );

# pull in the XS bits
XSLoader::load 'Net::TCPwrappers', $VERSION;

# let ExtUtils::Constant generate our AUTOLOAD function
my $autoload_func = ExtUtils::Constant::autoload('Net::TCPWrappers');
eval $autoload_func;
if( $@ ) {
    Carp::croak "can't set up Net::TCPWrappers::AUTOLOAD: $@";
}

# keep require happy
1;


__END__


=head1 ABSTRACT

Net::TCPwrappers offers perl programmers a convenient interface to the
libwrap.a library from tcp_wrappers, Wietse Venema's popular TCP/IP daemon
wrapper package.  Use it in your perl code to monitor and filter access to
TCP-based network services on unix hosts.

=head1 DESCRIPTION

Net::TCPwrappers mimics the libwrap.a library fairly closely - the names of
the functions and constants are identical, and calling arguments have been
altered only slightly to be more perl-like.

=head2 FUNCTIONS

This module defines all the public functions available in the libwrap.a
library: C<request_init>, C<request_set>, C<hosts_access>, and C<hosts_ctl>. 
None are exported by default; you must either add the package name when
calling them (eg, C<Net::TCPwrappers::request_init(...)>) or import them
explicitly (eg, C<use Net::TCPwrappers qw(request_init ...);>).

=over 4

=item request_init($key1, $value1, $key2, $value2, ...)

Creates a new request structure and initializes it using the supplied key /
value pairs.  The keys are used to specify the interpretation of the value
argument (eg, daemon name, file descriptor, host name, etc) and should be
one of the constants described below.  As many key / value pairs (for the
same request, of course) can be specified as desired.

Returns an integer representing a pointer to the newly created request
structure.  In the unlikely event of failure, the function returns undef. 
This may arise because memory can not be allocated for the request structure
or because the key / value pairs are not of the correct types.  [If the
later, make sure you're using the proper constants as described below.]

Note: the pointer to the request structure is blessed into the class
Request_infoPtr and will be automatically destroyed when the program exits.

=item request_set($request, $key1, $value1, $key2, $value2, ...)

Copies an existing request structure (represented by the pointer
C<$request>) into a new one and updates it using the supplied key / value
pairs, which are described above.

Returns an integer representing a pointer to the updated request structure. 
In the unlikely event of failure, the function returns undef.  This may
arise because memory can not be allocated for the request structure or
because the key / value pairs are not of the correct types.  [If the later,
make sure you're using the proper constants as described below.]

Note: the pointer to the request structure is blessed into the class
Request_infoPtr and will be automatically destroyed when the program exits.

=item fromhost($request))

Updates an existing request structure (pointed to by C<$request>) with the
port and address information obtained from the client and server endpoints.

Note: this should be used after C<request_init> or C<request_set> if either
is called with C<RQ_FILE>.

=item hosts_access($request)

Determines whether to allow access based on information in the request
structure pointed to by C<$request> along with the host access tables (see
L<hosts_access(5)>).

Returns 0 if access should be denied. 

=item hosts_ctl($daemon, $client_name, $client_addr [, $client_user])

Determines whether to allow access based on the supplied daemon name, host
name, host IP address, and optionally username of the client host making the
request.

Returns 0 if access should be denied. 

Note: this is implemented in libwrap.a as a wrapper around the
C<request_init> and C<hosts_access> functions.

=back

=head2 CONSTANTS

The keys used in the functions C<request_init> and C<request_set> and
their meanings are:

=over 4

=item RQ_CLIENT_ADDR

A string representing the client's IP address. 

=item RQ_CLIENT_NAME

A string representing the client's hostname. 

=item RQ_CLIENT_SIN

A pointer to the client's C<sockaddr_in> structure, representing its host
address and port.

=item RQ_DAEMON

A string representing the daemon's name as it appears in the access
control tables. 

Note: a key / value pair with C<RQ_DAEMON> must be supplied via either
C<request_init> or C<request_set> if calling C<hosts_access>.

=item RQ_FILE

An integer representing the file descriptor associated with the request. 

Note: C<fromhost> should be called after C<request_init> or C<request_set>
if using this key.

=item RQ_SERVER_ADDR

A string representing the server's IP address. 

=item RQ_SERVER_NAME

A string representing the server's hostname. 

=item RQ_SERVER_SIN

A pointer to the server's C<sockaddr_in> structure, representing its host
address and port.

=item RQ_USER

A string representing the name of the user making the request from the
client host.

=back

None of these are exported by default.

=head1 KNOWN BUGS AND CAVEATS

Currently, I am not aware of any bugs in this module.

=head1 DIAGNOSTICS

The routines in libwrap.a report problems via the syslog daemon.

=head1 SEE ALSO

L<hosts_access(5)>, libwrap.a documentation.

=head1 AUTHOR

George A. Theall, E<lt>theall@tifaware.comE<gt>

Currently maintained by James FitzGibbon, E<lt>jfitz@CPAN.orgE<gt>.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2002, George A. Theall. All Rights Reserved.
Copyright (c) 2004, James FitzGibbon.  All Rights Reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

#
# EOF
