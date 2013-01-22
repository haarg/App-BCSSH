package App::BCSSH::Message;
use strict;
use warnings;

use Exporter 'import';
use constant ();

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
our @EXPORT = (qw(make_response split_message join_message), keys %constants);

constant->import(\%constants);

sub make_response {
    my $type = shift;
    my $message = @_ ? (
        ref $_[0] ? join_message(@{ $_[0] }) : $_[0]
    ) : '';
    my $full_message = pack('c', $type) . $message;
    return pack('N', length $full_message) . $full_message;
}

sub split_message {
    my $message = shift;
    my @parts = split /\|/, $message;
    return (@parts);
}

sub join_message {
    my @message = @_;
    return join '|', @message;
}

1;

