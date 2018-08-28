#!perl6

use API::Discord;

sub MAIN($token) {
    my $c = API::Discord.new(:$token, :shard(0), :shards-max(1));

    my Promise $closer = await $c.connect;

    my @channels;

    react {
        CATCH {.say}
        whenever $c.messages -> $m {
            if $m<d><channels> {
                @channels := $m<d><channels>;
            }
            else {
                say $m;
                #say @channels;

                for @channels -> $chan {
                    if $chan<name> ~~ /spam/ {
                        $chan<id>.say;
                    }
                }
            }
            LAST { say "ok bye" }
        }
    }

    my $reason = await $closer;
    say await $reason.body;
}
