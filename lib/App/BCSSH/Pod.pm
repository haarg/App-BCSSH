package App::BCSSH::Pod;
use strict;
use warnings;

use Module::Reader qw(:all);

{
    use Pod::Simple::PullParser ();
    use Pod::Simple::Text ();
    @App::BCSSH::Pod::Parser::ISA = qw(Pod::Simple::PullParser Pod::Simple::Text);

    sub App::BCSSH::Pod::Parser::new {
        my $class = shift;
        my $self = $class->Pod::Simple::PullParser::new;
        my $alt = $class->Pod::Simple::Text::new;
        @$self{keys %$alt} = values %$alt;
        return $self;
    }
}

sub abstract {
    my $source = shift;
    my $parse = App::BCSSH::Pod::Parser->new;
    my $fh = Module::Reader::module_handle($source);
    $parse->set_source($fh);
    my $abstract = '';
    while (my $token = $parse->get_token) {
        if ($token->is_start && $token->tagname eq 'head1') {
            my $next = $parse->get_token;
            if ($next->is_text && $next->text eq 'NAME') {
                while (my $ff = $parse->get_token) {
                    last if $ff->is_end && $ff->tag eq 'head1';
                }
                while (my $abs = $parse->get_token) {
                    $abstract .= $abs->text if $abs->is_text;
                    last if $abs->is_start && $abs->tag =~ /^[a-z]/;
                }
            }
            else {
                $parse->unget_token($next);
            }
        }
    }
    $abstract =~ s/.*?\s+-\s+//;
    return $abstract;
}

sub options {
    my $source = shift;
    my $parse = App::BCSSH::Pod::Parser->new;
    my $fh = Module::Reader::module_handle($source);
    $parse->set_source($fh);
    my %options;
    while (my $token = $parse->get_token) {
        next
            until $token->is_start && $token->tagname eq 'head1';
        my $next = $parse->get_token;
        unless ($next->is_text && $next->text eq 'OPTIONS') {
            $parse->unget_token($next);
            next;
        }
        while (my $ff = $parse->get_token) {
            last if $ff->is_start && $ff->tag =~ /^over-/;
        }
        while (my $items = $parse->get_token) {
            next
                unless $items->is_start && $items->tag =~ /^item-/;

            my $option = '';
            while (my $opt = $parse->get_token) {
                last if $opt->is_end && $opt->tag =~ /^item-/;
                $option .= $opt->text if $opt->is_text;
            }

            my $opt_text = '';
            my $depth = 1;
            open my $fh, '>', \$opt_text;
            local $parse->{output_fh} = $fh;
            while (my $opt = $parse->get_token) {
                if (! $opt->is_text && $opt->tag =~ /^over-/) {
                    $depth += $opt->is_start ? 1 : -1;
                    last if $depth == 0;
                }

                if ($opt->is_text) {
                    $parse->handle_text($opt->text);
                    next;
                }
                my $m = $opt->type . '_' . $opt->tag;
                $parse->can($m) or next;

                $parse->$m( $opt->is_start ? $opt->attr_hash : () );
            }
            $opt_text =~ s/^    //gm;
            $opt_text =~ s/\n\n$//;

            $options{$option} = $opt_text;
        }
    }
    return \%options;
}

1;
