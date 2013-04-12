package App::BCSSH::Client;
use App::BCSSH::Message qw(send_message BCSSH_SUCCESS BCSSH_FAILURE BCSSH_COMMAND);
use JSON qw(encode_json decode_json);
use Moo::Role;

has 'agent' => ( is => 'ro', default => sub { $ENV{SSH_AUTH_SOCK} } );
has 'auth_key' => ( is => 'ro', default => sub { $ENV{LC_BCSSH_KEY} } );
has 'agent_socket' => ( is => 'lazy' );

sub _build_agent_socket {
    my $self = shift;
    require IO::Socket::UNIX;
    IO::Socket::UNIX->new(
        Peer => $self->agent,
    );
};

sub handler {
    my $self = shift;
    my $class = ref $self || $self;
    $class =~ s/.*:://;
    return $class;
}

sub command {
    my ($self, @args) = @_;
    my $key = $self->auth_key || '';
    my $message = join '|', $self->handler, $key, encode_json(\@args);
    my ($rtype, $rmessage) = send_message($self->agent_socket, BCSSH_COMMAND, $message);
    if (defined $rtype && $rtype == BCSSH_FAILURE && $rmessage) {
        die $rmessage;
    }
    if ($rtype != BCSSH_SUCCESS) {
        die "Error!";
    }
    unless (defined $rmessage && length $rmessage) {
        return;
    }
    my $response = decode_json($rmessage);
    return wantarray ? @$response : 1;
}

1;
