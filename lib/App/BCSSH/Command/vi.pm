package App::BCSSH::Command::vi;
use strict;
use warnings;

use Cwd;
use App::BCSSH::Client;
use App::BCSSH::Message;

sub run {
    my $class = shift;
    my $agent = $ENV{SSH_AUTH_SOCK} or exec 'vi', @_;
    my ($file) = @_;
    $file or die "file required\n";
    my $full_file = Cwd::abs_path($file);
    my ($type) = App::BCSSH::Client::send($agent, BCSSH_EDIT, $full_file);
    return $type == BCSSH_SUCCESS;
}

1;
