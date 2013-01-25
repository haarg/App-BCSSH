package App::BCSSH::Options;
use strictures 1;
use Package::Variant
    importing => ['Moo::Role'],
    subs => [ qw(has around before after with) ],
;
use Sub::Quote;

sub make_variant {
    my ($class, $target_package, %arguments) = @_;

    my $config = $class->default_config;
    if (my $in_config = delete $arguments{'-config'}) {
        for my $opt (keys %$in_config) {
            $config->{$opt} = $in_config->{$opt}
                if exists $config->{$opt};
        }
    }
    my @config = (
        'default',
        map { (
              $_ =~ /_pattern$/ ? "$_=$config->{$_}"
            : $config->{$_}     ? $_
                                : "no_$_"
        ) } keys %$config
    );

    my $error = delete $arguments{'-error'} || $class->default_error;
    my $arg_error = delete $arguments{'-arg_error'} || $class->default_arg_error;

    has args => (is => 'ro');

    around BUILDARGS => sub {
        my $orig = shift;
        my $class = shift;
        my @args = @_;
        my %opts;
        my @parse_args = map {
            ("$arguments{$_}" => \($opts{$_}))
        } keys %arguments;
        require Getopt::Long;
        my $parser = Getopt::Long::Parser->new(config => \@config);
        {
            local @ARGV = @args;
            local $SIG{__WARN__} = $arg_error;
            $parser->getoptions(@parse_args);
            @args = @ARGV;
        }
        if ($config->{passthrough}) {
            for my $idx (0..$#args) {
                if ($args[$idx] eq '--') {
                    splice @args, $idx, 1;
                    last;
                }
            }
        }
        for my $k (keys %opts) {
            delete $opts{$k} if !defined $opts{$k};
        }
        return $class->$orig({ args => \@args, %opts });
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

