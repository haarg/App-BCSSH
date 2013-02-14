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

sub fork { 0 }

sub _build_command {
    my $class = ref shift;
    $class =~ s/^\Q${\__PACKAGE__}:://;
    return lc $class;
}

sub handler {
    my $self = shift;
    return sub {
        my ($send, $args) = @_;
        if ($self->fork) {
            if (CORE::fork) {
                return;
            }
        }
        my $handler_args = decode_json($args);
        my @response = $self->handle(@$handler_args);
        my $rmessage = @response ? encode_json(\@response) : '';
        $send->(BCSSH_SUCCESS, $rmessage);
        if ($self->fork) {
            exit;
        }
    }
}

1;
