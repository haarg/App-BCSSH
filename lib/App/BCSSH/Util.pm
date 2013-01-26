package App::BCSSH::Util;

sub _getstash { \%{"$_[0]::"} }

use strict;
use warnings;

use Module::Runtime qw(require_module);

use base 'Exporter';
our @EXPORT_OK = qw(find_mods find_inline);

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
    push @mods, find_inline($ns);
    my %mods;
    @mods{@mods} = ();
    return sort keys %mods;
}

sub find_inline {
    my ($ns, $mark_loaded) = @_;

    my @mods;
    my @stash = ([$ns => _getstash($ns)]);
    while (my $s = pop @stash) {
        my ($base_ns, $stash) = @$s;
        if ( $base_ns ne $ns and my ($code) = grep { !ref $_ and *$_{CODE} } values %$stash ) {
            push @mods, $base_ns;
            if ($mark_loaded) {
                (my $file = "$base_ns.pm") =~ s{::}{/}g;
                $INC{$file} ||= 1;
                #$INC{$file} = B::svref_2object(*$code{CODE})->FILE;
            }
        }
        for my $sub ( grep { /::$/ } keys %$stash ) {
            push @stash, [ "$base_ns\::$sub", $stash->{$sub} ];
            $stash[-1][0] =~ s/::$//;
        }
    }
    return @mods;
}

1;

