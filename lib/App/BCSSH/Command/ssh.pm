package App::BCSSH::Command::ssh;
use Moo;
use Sub::Quote;
use App::BCSSH::Message;
use App::BCSSH::Proxy;
use App::BCSSH::Options;
use App::BCSSH::Util qw(find_mods);
use JSON qw(encode_json decode_json);
use constant DEBUG => $ENV{BCSSH_DEBUG};
use namespace::clean;

with Options(
    permute => 0,
);
with 'App::BCSSH::Help';

has agent_path => ( is => 'ro', default => quote_sub q[ $ENV{SSH_AUTH_SOCK} ] );
has host => ( is => 'ro', lazy => 1, default => quote_sub q{ $_[0]->find_host($_[0]->args) } );
has auth => ( is => 'ro', arg_spec => 'auth!' );
has auth_key => (
    is => 'ro',
    lazy => 1,
    default => quote_sub q[ join '', map { chr(32+int(rand(96))) } (1..20) ],
);
has proxy => ( is => 'lazy' );

has proxy_handlers => ( is => 'lazy' );
has command_handlers => ( is => 'lazy' );

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

sub _build_proxy_handlers {
    my $self = shift;
    my $command_handlers = $self->command_handlers;

    my $host = $self->host;
    if ( !$host || $self->is_bcssh_agent($self->agent_path) ) {
        return {};
    }

    my $auth_key = $self->auth && $self->auth_key;

    my %handlers = (
        (BCSSH_QUERY) => sub {
            my ($send, $message) = @_;
            $send->(BCSSH_SUCCESS);
        },
        (BCSSH_COMMAND) => sub {
            my ($send, $message) = @_;

            my ($command, $key, $args) = split /\|/, $message, 3;
            if ($auth_key && ! $auth_key ne $key) {
                return $send->(BCSSH_FAILURE);
            }
            my $command_handler = $command_handlers->{$command};
            if (!$command_handler) {
                return $send->(BCSSH_FAILURE);
            }
            my $handler_args = decode_json($args);
            my @response = $command_handler->(@$args);
            my $rmessage = @response ? encode_json(\@response) : '';
            $send->(BCSSH_SUCCESS, $rmessage);
        },
    );

    return \%handlers;
}

sub _build_command_handlers {
    my $self = shift;
    require App::BCSSH::Proxy::Handler;
    find_mods('App::BCSSH::Proxy::Handler', 1);

    my %command_handlers;
    for my $handmod ( App::BCSSH::Proxy::Handler->handlers ) {
        my $handler = $handmod->new(host => $self->host);
        $command_handlers{$handler->command} = sub {
            $handler->handle(@_);
        };
    }
    return \%command_handlers;
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
    return App::BCSSH::Message::ping(@_);
}

1;

__END__

=head1 NAME

App::BCSSH::Command::ssh - Connect to L<ssh|ssh> server with bcssh proxy running

=head1 SYNOPSIS

    bcssh ssh --auth my.server.com

    alias ssh='bcssh ssh --auth --'

=head1 DESCRIPTION

Connects to a server using SSH, with a BCSSH proxy running to allow sending commands back.

=head1 OPTIONS

=over 8

=item --auth

Use auth token.

=back

=cut
