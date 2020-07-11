#!perl6

use API::Discord;

sub MAIN($token) {
    my $discord = API::Discord.new(:$token);

    $discord.connect;
    await $discord.ready;

    react {
        whenever $discord.messages -> $message {
            $message.add-reaction('⭐');
        }
    }
}
