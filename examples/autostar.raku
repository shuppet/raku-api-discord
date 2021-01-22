#!perl6

use API::Discord;
use API::Discord::Types;

sub MAIN($token) {
    my $discord = API::Discord.new(:$token, intents => ([+|] INTENT::guilds, INTENT::guild-messages, INTENT::guild-message-reactions), version => 8);

    $discord.connect;
    await $discord.ready;

    react {
        whenever $discord.messages -> $message {
            $message.add-reaction('⭐');
        }
    }
}
