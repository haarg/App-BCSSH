package App::BCSSH::Proxy::Handler::Vi;
use Moo;
use Sub::Quote;
use App::BCSSH::Message;

with 'App::BCSSH::Proxy::Handler';

has gvim => (is => 'ro', default => sub { 'gvim' });

sub handle {
    my ($self, $args) = @_;
    my $files = $args->{files};
    my $wait = $args->{wait};
    for my $file (@$files) {
        $file = 'scp://'.$self->host.'/'.$file;
    }
    system $self->gvim, ($wait ? '-f' : ()), '--', @$files;
    return;
}

1;
