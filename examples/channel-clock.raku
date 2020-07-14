#!perl6

use API::Discord;

sub MAIN($token, $channel-id) {
    my $discord = API::Discord.new(:$token);

    $discord.connect;
    await $discord.ready;

    my $channel = $discord.get-channel($channel-id);

    react {
        whenever Supply.interval(60) {
            $channel.name = '🕒 ' ~ sprintf("%02d:%02d", .hour, .minute) given DateTime.now;
            $channel.update;
            CATCH {.say}
        }
    }
}
