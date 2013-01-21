package App::bcssh::command::ping;
use strict;
use warnings;
use App::bcssh::client;

sub run {
    my $class = shift;
    my $agent = $ENV{SSH_AUTH_SOCK} or return;
    return App::bcssh::client::ping($agent);
}

1;
