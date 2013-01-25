package App::BCSSH;
use strict;
use warnings;
our $VERSION = '0.00100';
$VERSION = eval $VERSION;

use Try::Tiny;
use Module::Runtime qw(use_module);
use Module::Find ();

sub run_script { exit($_[0]->new->run(@ARGV) ? 0 : 1) }
sub new { bless {}, $_[0] }

sub run {
    my $self = shift;
    my @args = @_;
    my $command = shift @args
        or die "Command required.\n" . $self->_commands_msg;
    $command =~ /^[a-z](?:-[a-z]+)*+$/
        or $self->invalid_command($command);
    return try {
        my $pack = "App::BCSSH::Command::$command";
        $pack =~ s/-/::/g;
        return use_module($pack)->new->run(@args);
    }
    catch {
        if (/Can't locate .+? in \@INC/) {
            $self->invalid_command($command);
        }
        else {
            die $_;
        }
    };
}

sub invalid_command {
    my $self = shift;
    my $command = shift;
    die "Invalid command $command!\n" . $self->_commands_msg;
}

sub _commands_msg {
    return "Available commands:\n" . (join '', map { "\t$_\n" } $_[0]->commands);
}

sub commands {
    my $self = shift;
    my $command_ns = 'App::BCSSH::Command';
    my @mods = _find_mods($command_ns);
    for (@mods) {
        s/^$command_ns\:://;
        s/::/-/g;
    }
    return sort @mods;
}

sub _find_mods {
    my $ns = shift;
    my @mods = Module::Find::findallmod($ns);
    if (defined &_fatpacker::modules) {
        push @mods, grep { /^$ns\::/ } _fatpacker::modules();
    }
    return @mods;
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
