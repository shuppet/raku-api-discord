#!perl6

use API::Discord;


sub MAIN($token) {
    my $discord = API::Discord.new(:$token);

    await $discord.connect;

    react {
        # We can't access $discord.user until we've received the READY event
        # When we do get that, we can ask for the list of guilds. Although we
        # always get a Promise, we only actualy fetch the list once.
        #
        # Some properties of objects return Promises because we have to fetch
        # them when requested. This will always return the same Promise, to
        # avoid race conditions.
        whenever $discord.events -> $event {
            if $event<t> eq 'READY' {
                say "Guilds: " ~ (await $discord.user.guilds).map: {$_.to-json};
            }
        }
    }
}
