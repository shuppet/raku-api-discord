#!perl6

use API::Discord;

sub MAIN($token) {
    my $c = API::Discord.new(:$token);

    await $c.connect;

    react {
        CATCH {.say}
        whenever $c.messages -> $m {
            say $m;
            LAST { say "ok bye" }
        }
    }
}
