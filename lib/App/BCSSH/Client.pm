package App::BCSSH::Client;
use Moo::Role;
use App::BCSSH::Message qw();

has 'agent' => ( is => 'ro', default => sub { $ENV{SSH_AUTH_SOCK} } );
has 'auth_key' => ( is => 'ro', default => sub { $ENV{LC_BCSSH_KEY} } );

sub message {
    my ($self, $type, @args) = @_;

    my ($rtype, @rargs) = App::BCSSH::Message::send_message($self->agent, $type, $self->auth_key||'', @args);
    $rtype ||= App::BCSSH::Message::SSH_AGENT_FAILURE;
    return wantarray ? ($rtype, @args) : $rtype;
}

1;
