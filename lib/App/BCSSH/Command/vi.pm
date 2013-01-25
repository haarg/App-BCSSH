package App::BCSSH::Command::vi;
use strict;
use warnings;

use Cwd;
use App::BCSSH::Client;
use App::BCSSH::Message;

sub run {
    my $class = shift;
    my $agent = $ENV{SSH_AUTH_SOCK} or exec 'vi', @_;
    my $auth_key = $ENV{LC_BCSSH_KEY} || '';
    my @files = @_;
    @files or die "At least one file must be specified!\n";
    for my $file (@files) {
        $file = File::Spec->rel2abs($file);
    }
    my ($type) = App::BCSSH::Client::send($agent, BCSSH_EDIT, $auth_key, @files);
    return $type && $type == BCSSH_SUCCESS;
}

1;
