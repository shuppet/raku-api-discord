#!perl6

use API::Discord;

sub MAIN($token) {
    my $c = API::Discord.new(:$token).connect;

    say $c.gist;

    my $conn = await $c;
    say $conn.gist;
}
