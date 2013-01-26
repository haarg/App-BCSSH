package App::BCSSH::Command::ssh;
use Moo;
use Sub::Quote;
use App::BCSSH::Message;
use App::BCSSH::Proxy;
use App::BCSSH::Client;
use App::BCSSH::Options;
use App::BCSSH::Util qw(find_mods);
use constant DEBUG => $ENV{BCSSH_DEBUG};

with Options(
    -config => {permute => 0},
    auth => 'auth!',
);

has agent_path => ( is => 'ro', default => quote_sub q[ $ENV{SSH_AUTH_SOCK} ] );
has host => ( is => 'ro', lazy => 1, default => quote_sub q{ $_[0]->find_host($_[0]->args) } );
has auth => ( is => 'ro' );
has auth_key => (
    is => 'ro',
    lazy => 1,
    default => quote_sub q[ join '', map { chr(32+int(rand(96))) } (1..20) ],
);
has proxy => ( is => 'lazy' );
has handlers => ( is => 'lazy' );

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
    # ssh closes all extra file descriptors, or this could use exec with a non-close-on-exec fd
    exit system('ssh', @$args);
}

sub _build_handlers {
    my $self = shift;
    require App::BCSSH::Proxy::Handler;
    find_mods('App::BCSSH::Proxy::Handler', 1);

    my $host = $self->host;

    if ( !$host || $self->is_bcssh_agent($self->agent_path) ) {
        my $fail = sub { $_[0]->(SSH_AGENT_FAILURE) };
        return {
            map { $_->message_type => $fail } App::BCSSH::Proxy::Handler->handlers;
        };
        undef $host;
    }

    my $auth_key = $self->auth && $self->auth_key;
    my %handlers;

    for my $handmod ( App::BCSSH::Proxy::Handler->handlers ) {
        my $handler = $handmod->new(host => $self->host);
        my %captures = (
            '$handler' => \$handler,
            $auth_key ? ( '$auth_key' => \$auth_key ) : (),
        );
        my $code = ($auth_key ? 'die if $auth_key ne ' : '') . q{splice @_, 1, 1;};
        if (my $inline = quoted_from_sub($handler->can('handle'))) {
            %captures = ( %captures, %{ $inline->[2] } )
                if $inline->[2];
            $code .= q{unshift @_, $handler;} . $inline->[1];
        }
        else {
            $code .= q{$handler->handle(@_);};
        }
        $handlers{$handler->message_type}
            = quote_sub($code, \%captures, { no_install => 1 });
    }
    return \%handlers;
}

sub _build_proxy {
    my $self = shift;
    return App::BCSSH::Proxy->new(
        agent_path => $self->agent_path,
        handlers => $self->handlers,
    );
}

sub proxy_guard {
    my ($self, $child_cb) = @_;
    my $proxy = $self->proxy;

    my $child = open my $fh, '|-';
    if (!$child) {
        chdir '/';
        $0 = 'bcssh proxy';
        unless (DEBUG) {
            open STDOUT, '>', '/dev/null';
            open STDERR, '>', '/dev/null';
        }
        $proxy->proxy(\*STDIN);
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

