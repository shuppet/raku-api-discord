#!perl6

use API::Discord;


sub MAIN($token, $channel-id) {
    my $discord = API::Discord.new(:$token);

    $discord.connect;
    await $discord.ready;

    my $channel = await $discord.get-channel($channel-id);
    
    react {
        whenever Supply.interval(60) {
            $channel.name = '🕒 ' ~ .hour ~ ':' ~ .minute given DateTime.now;
            $channel.update;
            CATCH {.say}
        }
    }
}
