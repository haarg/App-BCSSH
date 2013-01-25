package App::BCSSH::Command::ssh;
use Moo;
use Sub::Quote;
use App::BCSSH::Message;
use App::BCSSH::Proxy;
use App::BCSSH::Client;
use App::BCSSH::Options;

with Options(
    -config => {permute => 0},
    auth => 'auth!',
);

has agent_path => ( is => 'ro', default => quote_sub q[ $ENV{SSH_AUTH_SOCK} ] );
has host => ( is => 'ro', lazy => 1, default => quote_sub q{ $_[0]->find_host($_[0]->args) } );
has gvim => ( is => 'ro', default => quote_sub q{ 'gvim' });
has auth => ( is => 'ro' );
has auth_key => (
    is => 'ro',
    lazy => 1,
    default => quote_sub q[ join '', map { chr(32+int(rand(96))) } (1..20) ],
);
has proxy => ( is => 'lazy' );

sub run {
    my $self = shift;
    my $args = $self->args;
    my $host = $self->host;
    if (! $host) {
        exec 'ssh', @$args;
    }
    my $proxy = $self->proxy;
    $ENV{SSH_AUTH_SOCK} = $proxy->socket_path;
    if ($host && $self->auth) {
        $ENV{LC_BCSSH_AUTH} = $self->auth_key;
    }
    my $guard = $self->proxy_guard;
    exit system('ssh', @$args);
}

sub _build_proxy {
    my $self = shift;
    my $host = $self->host;
    my $agent_path = $self->agent_path;
    if ($self->is_bcssh_agent($agent_path)) {
        undef $host;
    }
    my $gvim = $self->gvim;
    my $auth_key = $self->auth && $self->auth_key;
    my $check_key = $auth_key ? sub { die if $_[0] ne $auth_key } : sub () {};
    return App::BCSSH::Proxy->new(
        agent_path => $agent_path,
        handlers => {
            $host ? (
                (BCSSH_QUERY) => sub {
                    my ($send, $key) = @_;
                    $check_key->($key);
                    $send->(BCSSH_SUCCESS);
                },
                (BCSSH_EDIT) => sub {
                    my ($send, $key, $file) = @_;
                    $check_key->($key);
                    my $file_path = "scp://$host/$file";
                    fork or exec $gvim, '--', $file_path;
                    $send->(BCSSH_SUCCESS);
                },
            ) : (
                map { $_ => sub { $_[0]->(SSH_AGENT_FAILURE) } } (
                    BCSSH_QUERY,
                    BCSSH_EDIT,
                ),
            ),
        },
    );
}

sub proxy_guard {
    my ($self, $child_cb) = @_;
    my $proxy = $self->proxy;

    my $child = open my $fh, '|-';
    if (!$child) {
        chdir '/';
        $0 = 'bcssh proxy';
        open STDOUT, '>', '/dev/null';
        open STDERR, '>', '/dev/null';
        $proxy->(\*STDIN);
        exit;
    }
    return $fh;
}

sub find_host {
    my $self = shift;
    my $args = shift;

    my %need_arg = map { $_ => 1} split //, 'bcDeFiLlmOopRS';

    my $user;
    my $host;
    my $port;
    for (my $idx = 0; $idx < @$args; $idx++) {
        my $arg = $args->[$idx];
        if ($arg =~ /^-([bcDeFiLlmOopRS])(.*)/){
            my $val = length $2 ? $2 : $args->[++$idx];
            if ($1 eq 'l') {
                $user = $val;
            }
            elsif ($1 eq 'p') {
                $port = $val;
            }
        }
        elsif ($arg =~ /^--/) {
            last;
        }
        elsif ($arg !~ /^-/ && !defined $host) {
            $host = $arg;
        }
    }
    return unless defined $host;
    my $target = '';
    $target .= "$user@"
        if defined $user && $host !~ /@/;
    $target .= $host;
    $host .= ":$port"
        if defined $port && $host !~ /:/;
    return $target;
}

sub is_bcssh_agent {
    my $self = shift;
    return App::BCSSH::Client::ping(@_);
}

1;

