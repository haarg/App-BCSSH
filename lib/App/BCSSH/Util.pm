package App::BCSSH::Util;

sub _getstash { \%{"$_[0]::"} }

use strict;
use warnings;

use Module::Runtime qw(require_module);

use base 'Exporter';
our @EXPORT_OK = qw(find_mods command_to_package package_to_command);

sub find_mods {
    my ($ns, $load) = @_;
    require Module::Find;
    my @mods = Module::Find::findallmod($ns);
    if (defined &_fatpacker::modules) {
        push @mods, grep { /^$ns\::/ } _fatpacker::modules();
    }
    if ($load) {
        for my $mod (@mods) { require_module($mod) }
    }
    my %mods;
    @mods{@mods} = ();
    return sort keys %mods;
}

sub command_to_package {
    my $command = shift;
    $command =~ s/-/::/g;
    return "App::BCSSH::Command::$command";
}

sub package_to_command {
    my $package = shift;
    $package =~ s/::/-/g;
    $package =~ s/^App::BCSSH::Command:://;
    return $package;
}

1;

