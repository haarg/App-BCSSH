package App::BCSSH::Command::commands;
use strictures 1;

use App::BCSSH::Util qw(find_mods);
use App::BCSSH::Pod;

sub new { bless {}, $_[0] }

sub run {
    my $self = shift;
    print $self->commands_message;
}

sub commands_message {
    my $self = shift;
    my $msg = "Available commands:\n";
    for my $command (sort keys %$commands) {
        $msg .= sprintf "\t%-15s %s\n", $command, $commands->{$command};
    }
    return $msg;
}

sub get_commands {
    my $command_ns = 'App::BCSSH::Command';
    my @mods = find_mods($command_ns);
    return { map {
        my $command = $_;
        my $abstract = App::BCSSH::Pod::abstract($command);
        $command =~ s/^$command_ns\:://;
        $command =~ s/::/-/g;
        ( $command, $abstract )
    } @mods };
}

1;

__END__

=head1 NAME

App::BCSSH::Command::commands - list commands available to bcssh

=cut
