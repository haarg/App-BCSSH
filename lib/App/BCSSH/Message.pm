package App::BCSSH::Message;
use strict;
use warnings;

use Exporter 'import';
use constant ();

BEGIN {
    my %constants = (
        BCSSH_QUERY     => -40,
        BCSSH_SUCCESS   => -41,
        BCSSH_FAILURE   => -42,
        BCSSH_COMMAND   => -43,
        BCSSH_EDIT      => -44,

        SSH_AGENTC_REQUEST_RSA_IDENTITIES   => 1,
        SSH_AGENT_RSA_IDENTITIES_ANSWER     => 2,
        SSH_AGENTC_RSA_CHALLENGE            => 3,
        SSH_AGENT_RSA_RESPONSE              => 4,
        SSH_AGENT_FAILURE                   => 5,
        SSH_AGENT_SUCCESS                   => 6,

        SSH2_AGENTC_REQUEST_IDENTITIES      => 11,
        SSH2_AGENT_IDENTITIES_ANSWER        => 12,
        SSH2_AGENTC_SIGN_REQUEST            => 13,
        SSH2_AGENT_SIGN_RESPONSE            => 14,

        SSH_COM_AGENT2_FAILURE              => 102,
    );
    our %EXPORT_TAGS = (message_types => [keys %constants]);
    our @EXPORT_OK = (qw(make_response split_message join_message send_message), keys %constants);
    our @EXPORT = @EXPORT_OK;
    $EXPORT_TAGS{all} = [@EXPORT_OK];

    constant->import(\%constants);
}

sub make_response {
    my $type = shift;
    my $message = join_message(@_);
    my $full_message = pack('c', $type) . $message;
    return pack('N', length $full_message) . $full_message;
}

sub split_message {
    my $message = shift;
    my @parts = split /(?<!\\)\|/, $message;
    s/\\(.)/$1/g for @parts;
    return @parts;
}

sub join_message {
    my @message = @_;
    return join '|', @message;
}

sub send_message {
    my $path = shift;
    require IO::Socket::UNIX;

    my $agent = IO::Socket::UNIX->new(
        Peer => $path,
    );

    $agent->syswrite(make_response(@_));
    my ($type, $message) = read_message($agent);
    $agent->close;
    return ($type, split_message($message));
}

sub read_message {
    my $agent = shift;
    $agent->sysread(my $buf, 4);
    my $left = unpack 'N', $buf;
    my $message = '';
    while (my $read = $agent->sysread($buf, $left)) {
        $message .= $buf;
        $left -= $read;
    }
    if ($left) {
        return;
    }
    my $type = unpack 'c', substr($message, 0, 1, '');
    return ($type, $message);
}

sub ping {
    my $agent = shift;
    my ($type) = send_message($agent, BCSSH_QUERY);
    return($type && $type == BCSSH_SUCCESS);
}

1;
