package App::BCSSH::Client;
use strict;
use warnings;

use App::BCSSH::Message;
use IO::Socket::UNIX;

sub send {
    my $path = shift;

    my $agent = IO::Socket::UNIX->new(
        Peer => $path,
    );

    $agent->syswrite(make_response(@_));
    my ($type, $message) = read_message($agent);
    $agent->close;
    return ($type, $message);
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
    my ($type) = App::BCSSH::Client::send($agent, BCSSH_QUERY);
    return $type == BCSSH_SUCCESS;
}

1;

