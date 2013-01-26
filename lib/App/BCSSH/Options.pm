package App::BCSSH::Options;
use strictures 1;
use Package::Variant
    importing => ['Moo::Role'],
    subs => [ qw(has around before after with) ],
;
use Sub::Quote;
use Carp;

sub make_variant {
    my ($class, $target_package, %in_config) = @_;

    my %arguments;
    my $error     = delete $in_config{'-error'}     || $class->default_error;
    my $arg_error = delete $in_config{'-arg_error'} || $class->default_arg_error;

    my $config = $class->default_config;
    for my $opt (keys %in_config) {
        $config->{$opt} = $in_config{$opt}
            if exists $config->{$opt};
    }
    my @config = (
        'default',
        map { (
              $_ =~ /_pattern$/ ? "$_=$config->{$_}"
            : $config->{$_}     ? $_
                                : "no_$_"
        ) } keys %$config
    );
    my $parser;
    my $parse = sub {
        my $args = shift;
        $parser ||= do {
            require Getopt::Long;
            Getopt::Long::Parser->new(config => \@config);
        };

        my %opts;
        my @parse_args = map {
            ("$arguments{$_}" => \($opts{$_}))
        } keys %arguments;
        {
            local @ARGV = @$args;
            local $SIG{__WARN__} = $arg_error;
            $parser->getoptions(@parse_args) or $error->();
            @$args = @ARGV;
        }
        for my $k (keys %opts) {
            delete $opts{$k} if !defined $opts{$k};
        }
        if ($config->{passthrough}) {
            for my $idx (0..$#$args) {
                if ($args->[$idx] eq '--') {
                    splice @$args, $idx, 1;
                    last;
                }
            }
        }
        return \%opts;
    };

    has args => (is => 'ro', default => sub { [] });

    around has => sub {
        my ($orig, $attr, %attr_config) = @_;
        if (my $spec = delete $attr_config{arg_spec}) {
            my $attr_name = $attr;
            if (exists $attr_config{init_arg}) {
                if (!defined $attr_config{init_arg}) {
                    croak "Can't define a arg_spec for an attribute with init_arg => undef";
                }
                $attr_name = $attr_config{init_arg};
            }
            $arguments{$attr_name} = $spec;
        }
        $orig->($attr, %attr_config);
    };

    around BUILDARGS => sub {
        my $orig = shift;
        my $class = shift;
        if (@_ == 1 && ref $_[0]) {
            return $class->$orig(@_);
        }
        my $args = [@_];
        my $opts = $parse->($args);
        $opts->{args} = $args;
        return $class->$orig($opts);
    };
}

sub default_config {{
    auto_abbrev         => 0,
    gnu_compat          => 1,
    permute             => 0,
    bundling            => 1,
    bundling_override   => 0,
    ignore_case         => 0,
    ignore_case_always  => 0,
    pass_through        => 1,
    prefix_pattern      => '--|-',
    long_prefix_pattern => '--',
    debug               => 0,
}}

sub default_error {
    sub { die "Bad arguments!\n" }
}

sub default_arg_error {
    sub { warn $_[0] }
}

1;
