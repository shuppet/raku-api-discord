#!perl6

use API::Discord;

sub MAIN($token) {
    my $c = API::Discord.new(:$token);

    await $c.connect;

    react {
        whenever $c.messages -> $m {
            say "something";
        }
    }
}
