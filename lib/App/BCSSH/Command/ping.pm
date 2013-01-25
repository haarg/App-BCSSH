package App::BCSSH::Command::ping;
use strict;
use warnings;
use App::BCSSH::Client;

sub new { bless { agent => $ENV{SSH_AUTH_SOCK} }, $_[0] }

sub run {
    my $self = shift;
    my $agent = $self->{agent} or return;
    return App::BCSSH::Client::ping($agent);
}

1;
