#!perl6

use API::Discord;

sub MAIN($token) {
    my $discord = API::Discord.new(:$token, :script-mode);

    $discord.connect;
    await $discord.ready;

    react {
        whenever $discord.messages -> $message {
            $message.channel.send-message($message.content);
        }
    }
}
