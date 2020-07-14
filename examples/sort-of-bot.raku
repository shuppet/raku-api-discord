#!perl6

use API::Discord;

sub MAIN($token) {
    my $discord = API::Discord.new(:$token);

    await $discord.connect;

    react {
        whenever $discord.messages -> $message {
            if $message.addressed {
                my $c = $message.content;
                my Str $id = $discord.user.real-id;
                $c ~~ s/^ '<@' $id '>' \s+//;

                given $c {
                    when 'pin' {
                        await $message.pin;
                    }
                }
            }
        }
    }
}

