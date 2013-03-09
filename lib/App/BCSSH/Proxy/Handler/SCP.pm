package App::BCSSH::Proxy::Handler::SCP;
use Moo;
my $have_pty;
BEGIN { eval {require IO::Pty::Easy; $have_pty = 1} }

with 'App::BCSSH::Proxy::Handler';

has destination => (
    is => 'ro',
    default => sub {
        -d && return $_
            for ("$ENV{HOME}/Desktop", "$ENV{HOME}/desktop", $ENV{HOME});
    },
);

sub _build_fork { 1 }

sub handle {
    my ($self, $args) = @_;
    my $files = $args->{files};
    for my $file (@$files) {
        $file = $self->host.':'.$file;
    }
    return sub {
        my ($send, $socket) = @_;
        $send->();
        my @command = ('scp', '-r', '--', @$files, $self->destination);
        if ($have_pty) {
            my $pty = IO::Pty::Easy->new;
            $pty->spawn(@command);

            while ($pty->is_active) {
                my $output = $pty->read;
                last if defined($output) && $output eq '';
                $socket->syswrite($output);
            }
            $pty->close;
        }
        else {
            system @command;
        }
        $socket->shutdown(2);
    };
}

1;
