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

sub _build_command {
    my $class = ref shift;
    $class =~ s/^\Q${\__PACKAGE__}:://;
    return lc $class;
}

sub handle_message {
    my ($self, $args, $send, $socket) = @_;
    my $json_send = sub {
        my @response = @_;
        my $rmessage = @response ? encode_json(\@response) : '';
        $send->(BCSSH_SUCCESS, $rmessage);
    };
    my $handler_args = decode_json($args);
    my @response = $self->handle($json_send, @$handler_args);
    $json_send->(@response);
    return;
}

sub handler {
    my $self = shift;
    return sub {
        my ($args, $send, $socket) = @_;
        $self->handle_message($args, $send, $socket);
    }
}

1;
