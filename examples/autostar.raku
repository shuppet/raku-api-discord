use API::Discord;
use API::Discord::Debug;

sub MAIN($token) {
    my $discord = API::Discord.new(:$token);

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
