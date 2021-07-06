use API::Discord;
use API::Discord::Debug;
use API::Discord::Types;

sub MAIN($token) {
    my $discord = API::Discord.new(:$token, intents => ([+|] INTENT::guilds, INTENT::guild-messages, INTENT::guild-message-reactions));

    $discord.connect;
    await $discord.ready;

    react {
        whenever $discord.messages -> $message {
            $message.add-reaction('⭐');
        }
        whenever $discord.events -> $event {
            if $event<t> eq 'MESSAGE_REACTION_ADD' {
                say $event<d><member><user><username> ~ '#' ~ $event<d><member><user><discriminator> ~ ' added a reaction to message ' ~ $event<d><message_id>;
            }
        }
    }
}
