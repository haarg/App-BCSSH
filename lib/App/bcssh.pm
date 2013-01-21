package App::bcssh;
use strict;
use warnings;
our $VERSION = '0.00100';

sub run {
    my $class = shift;
    my @args = @_;
    my $command = shift @args or die "no command given";
    $command =~ /^[a-z]+$/ or die "bad command $command\n";
    if (my $sub = $class->can("command_$command")) {
        exit ($class->$sub(@args) ? 0 : 1);
    }
    elsif (eval { require "App/bcssh/command/$command.pm" }) {
        my $pack = "App::bcssh::command::$command";
        exit ($pack->run(@args) ? 0 : 1);
    }
    elsif ($@ =~ /^Can't locate .+? in \@INC/) {
        die "can't find command $command\n";
    }
    die $@;
}

1;
