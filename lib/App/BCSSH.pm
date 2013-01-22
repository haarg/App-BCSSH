package App::BCSSH;
use strict;
use warnings;
our $VERSION = '0.00100';

sub run {
    my $class = shift;
    my @args = @_;
    my $command = shift @args or die "no command given";
    $command =~ /^[a-z]+$/ or die "bad command $command\n";
    if (my $sub = $class->can("command_$command")) {
        exit ($class->$sub(@args) ? 0 : 1);
    }
    elsif (eval { require "App/BCSSH/Command/$command.pm" }) {
        my $pack = "App::BCSSH::Command::$command";
        exit ($pack->run(@args) ? 0 : 1);
    }
    elsif ($@ =~ /^Can't locate .+? in \@INC/) {
        die "can't find command $command\n";
    }
    die $@;
}

1;

__END__

=head1 NAME

App::BCSSH - Back channel SSH messaging

=head1 SYNOPSIS

    client$ bcssh ssh host
    host$ bcssh vi file

    bcssh ping && alias vi=bcssh vi

=head1 DESCRIPTION

This module enables commands on run on a server to be forwarded
back to the client that established the SSH connection.  Specifically,
it is meant to enable opening files in a local editor via commands
run on the server.

This is same concept that bcvi uses, but using a different messaging
protocol to fix some issues with it's design.

bcvi uses remote port forwards to enable communicating with the
local machine.  These may not be enabled on the server.  It also
overloads the TERM environment variable to pass information to the
server, but this is problematic if the server doesn't have bcvi set
up on it to fix TERM.

SSH already provides a mechanism for the server to communicate with
the client machine in the form of ssh agent forwarding.  bcssh
abuses this protocol to allow passing custom messages.  It sets
itself up as a proxy for the messages, passing through most messages.
It can identify messages intended for BCSSH though, and use this
to pass arbitrary information back and forth to the server.  This
also allows the server to probe the agent for BCSSH support, removing
the need to overload TERM.

=head1 CAVEATS

This is all probably a terrible idea.

=head1 AUTHOR

haarg - Graham Knop (cpan:HAARG) <haarg@haarg.org>

=head2 CONTRIBUTORS

None yet.

=head1 COPYRIGHT

Copyright (c) 2013 the App::FatPacker L</AUTHOR> and L</CONTRIBUTORS>
as listed above.

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself.

=cut
