#!raku

use API::Discord;

sub MAIN($token) {
    my $discord = API::Discord.new(:$token);

    $discord.connect;
    await $discord.ready;

    react {
        whenever $discord.messages -> $message {
            my $dm = await $discord.user.create-dm($message.author);
            $dm.send-message($message.content);
        }
    }
}
