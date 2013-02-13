package App::BCSSH::Client;
use strictures 1;
use Package::Variant
    importing => ['Moo::Role'],
    subs => [ qw(has around before after with) ],
;

use App::BCSSH::Message qw(send_message BCSSH_SUCCESS BCSSH_FAILURE BCSSH_COMMAND);
use JSON qw(encode_json decode_json);

sub make_variant {
    my ($class, $target_package, $command) = @_;

    has 'agent' => ( is => 'ro', default => sub { $ENV{SSH_AUTH_SOCK} } );
    has 'auth_key' => ( is => 'ro', default => sub { $ENV{LC_BCSSH_KEY} } );

    install 'command' => sub {
        my ($self, @args) = @_;
        my $key = $self->auth_key || '';
        my $message = join '|', $command, $key, encode_json(\@args);
        my ($rtype, $rmessage) = send_message($self->agent, BCSSH_COMMAND, $message);
        if (defined $rtype && $rtype == BCSSH_FAILURE && $rmessage) {
            die $rmessage;
        }
        if ($rtype != BCSSH_SUCCESS) {
            die "Error!";
        }
        unless (defined $message && length $message) {
            return;
        }
        my $response = decode_json($rmessage);
        return wantarray ? @$response : 1;
    };
}

1;
