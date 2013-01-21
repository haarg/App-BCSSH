package App::bcssh::command::ssh;
use strict;
use warnings;

use POSIX ":sys_wait_h";
use App::bcssh::message;
use App::bcssh::proxy;
use App::bcssh::client;

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    return $self;
}

sub run {
    my $self = ref $_[0] ? shift : shift->new;
    my $args = [@_];
    my $agent_path = $ENV{SSH_AUTH_SOCK};
    my $host = $self->find_host($args);
    if (! $host) {
        exec 'ssh', @$args;
    }
    if ($self->is_bcssh_agent($agent_path)) {
        die "not supported";
    }
    my $proxy = App::bcssh::proxy->new(
        agent_path => $agent_path,
        handlers => {
            (BCSSH_QUERY) => sub {
                $_[0]->(BCSSH_SUCCESS);
            },
            (BCSSH_EDIT) => sub {
                my ($send, $file) = @_;
                my $file_path = "scp://$host/$file";
                fork or exec 'gvim', '--', $file_path;
                $send->(BCSSH_SUCCESS);
            },
        },
    );
    my $proxy_sock = $proxy->socket_path;
    $ENV{SSH_AUTH_SOCK} = $proxy_sock;
    my $child = fork;
    if (!$child) {
        chdir '/';
#        open STDIN, '<', '/dev/null';
#        open STDERR, '>', '/dev/null';
#        open STDERR, '>', '/dev/null';
        $proxy->proxy;
        exit;
    }
    my $out = system 'ssh', @$args;
    waitpid($child, WNOHANG) != -1 and kill 'HUP', $child;
    exit $out;
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
    return App::bcssh::client::ping(@_);
}

1;

