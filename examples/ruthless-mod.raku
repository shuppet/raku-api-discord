#!perl6

use API::Discord;

sub MAIN($token) {
    my $discord = API::Discord.new(:$token);

    await $discord.connect;

    react {
        whenever $discord.messages -> $message {
            await $message.delete
        }
    }
}
