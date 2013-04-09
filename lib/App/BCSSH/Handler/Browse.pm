package App::BCSSH::Handler::Browse;
use Moo;
use Browser::Open qw(open_browser);

with 'App::BCSSH::Handler';

has browser => (is => 'ro');
has browse => (is => 'lazy', init_arg => undef);
sub _build_browse {
    my $self = shift;
    my $browser = $self->browser;
    $browser ? sub { system $browser, @_ } : \&open_browser;
}

sub handle {
    my ($self, $send, $args) = @_;
    my $urls = $args->{urls};

    for my $url (@$urls) {
        $self->browse->($url);
    }
    $send->();
}

1;
