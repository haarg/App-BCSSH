package App::BCSSH::Command::ping;
use strict;
use warnings;
use App::BCSSH::Client;

sub run {
    my $class = shift;
    my $agent = $ENV{SSH_AUTH_SOCK} or return;
    return App::BCSSH::Client::ping($agent);
}

1;
