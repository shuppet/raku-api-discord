#!perl6

use API::Discord;


sub MAIN($token) {
    my $discord = API::Discord.new(:$token);

    await $discord.connect;

    react {
        # We can't access $discord.user until we've received the READY event
        # When we do get that, we can ask for the list of guilds. Although we
        # get a Promise, we only actualy fetch the list once.
        #
        # Both of these principles apply to everything that has a separate
        # endpoint, but we may reconsider the architecture to simplify that.
        whenever $discord.events -> $event {
            if $event<t> eq 'READY' {
                say "Guilds: " ~ (await $discord.user.guilds);
            }
        }
    }
}
