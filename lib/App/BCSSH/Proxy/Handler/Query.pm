package App::BCSSH::Proxy::Handler::Query;
use Moo;
use App::BCSSH::Message;

with 'App::BCSSH::Proxy::Handler';

sub message_type { BCSSH_QUERY }

sub handle {
    my ($self, $send, $wait, @files) = @_;
    $send->(BCSSH_SUCCESS);
}

1;
