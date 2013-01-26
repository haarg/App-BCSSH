package App::BCSSH::Proxy::Handler;
use strictures 1;

my %handlers;
sub handlers {
    return sort keys %handlers;
}

use Moo::Role;
use MooX::CaptainHook qw(on_application);

has host => (is => 'ro', required => 1);
requires 'message_type';

on_application { $handlers{$_} = 1 };

1;
