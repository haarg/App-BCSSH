package App::BCSSH::Util;
use strictures 1;

use base 'Exporter';
our @EXPORT_OK = qw(find_mods command_to_package package_to_command rc_dir);

sub find_mods {
    my ($ns, $load) = @_;
    require Module::Pluggable::Object;
    return Module::Pluggable::Object->new(
      search_path => $ns,
      require => $load,
    )->plugins;
}

sub command_to_package {
    my $command = shift;
    $command =~ s/-/::/g;
    return "App::BCSSH::Command::$command";
}

sub package_to_command {
    my $package = shift;
    $package =~ s/^App::BCSSH::Command:://;
    $package =~ s/::/-/g;
    return $package;
}

sub rc_dir {
    my $config_base = $ENV{XDG_CONFIG_HOME} || "$ENV{HOME}/.config";
    return "$config_base/bcssh";
}

1;
__END__

=head1 NAME

App::BCSSH::Util - Utility functions for App::BCSSH

=head1 SYNOPSIS

    use App::BCSSH::Util qw(find_mods command_to_package package_to_command rc_dir);

=cut
