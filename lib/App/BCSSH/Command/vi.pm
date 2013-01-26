package App::BCSSH::Command::vi;
use Moo;
use App::BCSSH::Options;
with Options();
with 'App::BCSSH::Client';

use File::Spec;
use App::BCSSH::Message ':message_types';

has 'wait' => (is => 'ro', coerce => sub { $_[0] ? 1 : 0 }, arg_spec => 'f');

sub run {
    my $self = shift;
    my @files = @_;
    @files or die "At least one file must be specified!\n";
    for my $file (@files) {
        $file = File::Spec->rel2abs($file);
    }
    my $result = $self->message(BCSSH_EDIT, $self->wait, @files);
    return $result == BCSSH_SUCCESS;
}

1;
