package App::BCSSH::Proxy::Handler;
use Moo::Role;
use JSON qw(encode_json decode_json);
use App::BCSSH::Message;
use MooX::CaptainHook qw(on_application);

my %handlers;
sub handlers {
    return sort keys %handlers;
}

on_application { $handlers{$_} = 1 };

has host => (is => 'ro', required => 1);
has command => (is => 'lazy');
has fork => (is => 'lazy');
sub _build_fork { 0 };

sub _build_command {
    my $class = ref shift;
    $class =~ s/^\Q${\__PACKAGE__}:://;
    return lc $class;
}

sub handle_message {
    my ($self, $args, $send, $socket) = @_;
    if ($self->fork) {
        if (CORE::fork) {
            return;
        }
    }
    my $handler_args = decode_json($args);
    my $json_send = sub {
        my @response = @_;
        my $rmessage = @response ? encode_json(\@response) : '';
        $send->(BCSSH_SUCCESS, $rmessage);
    };
    my @response = $self->handle(@$handler_args);
    if (@response == 1 && eval { \&{$response[0]} }) {
        $response[0]->($json_send, $socket);
    }
    else {
        $json_send->(@response);
    }
    if ($self->fork) {
        exit;
    }
}

sub handler {
    my $self = shift;
    return sub {
        my ($args, $send, $socket) = @_;
        $self->handle_message($args, $send, $socket);
    }
}

1;
