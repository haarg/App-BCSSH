package App::BCSSH::Proxy::Handler::Vi;
use Moo;
use Sub::Quote;
use App::BCSSH::Message;

with 'App::BCSSH::Proxy::Handler';

sub message_type { BCSSH_EDIT }

has gvim => (is => 'ro', default => sub { 'gvim' });

quote_sub __PACKAGE__.'::handle' => q{
    my ($self, $send, $wait, @files) = @_;
    for my $file (@files) {
        $file = 'scp://'.$self->host.'/'.$file;
    }
    fork or exec $self->gvim, '--', @files;
    $send->($success);
}, {'$success' => \BCSSH_SUCCESS};

1;
