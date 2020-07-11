#!perl6

use API::Discord;

sub MAIN($token, $channel-id) {
    my $discord = API::Discord.new(:$token);

    $discord.connect;
    await $discord.ready;

    react {
        whenever Supply.interval(300) {
            my $time = DateTime.now;
            $discord.get-channel($channel-id).send-message("Test message sent at $time.");
        }
    }
}
