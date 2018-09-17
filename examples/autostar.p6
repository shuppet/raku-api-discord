#!perl6

use API::Discord;

sub MAIN($token) {
    my $discord = API::Discord.new(:$token);

    await $discord.connect;

    react {
        whenever $discord.messages -> $message {
            # These return Promises that we're ignoring.
            # Real code should await these and check for errors
            $message.add-reaction('⭐');
            $message.add-reaction('awoo:486257857277460490')
        }
    }
}
