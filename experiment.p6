use Cro::WebSocket::Client;

my $client = Cro::WebSocket::Client.new: :json;
my $conn-promise = $client.connect('wss://gateway.discord.gg/?v=6&encoding=json');

my $conn = await $conn-promise;

my $message-supply = $conn.messages;
my $last-sq;
my $hb-supply;

react {
    whenever $message-supply -> $m {
        my $json = await $m.body if $m.is-text;
        say $json;
#        if $json<s> {
#            $last-sq = $json<s>;
#        }
#
        if $json<op> == 10 {
            my $heartbeat-interval = $json<d><heartbeat_interval> / 1000;

            say $heartbeat-interval;
            $hb-supply = Supply.interval($heartbeat-interval);

            $hb-supply.tap: {
                    say "♥";
                    $conn.send({
                        d => $last-sq,
                        op => 251,
                    });
                },
                done => {say "out of numbers :("}
            ;
        }
        LAST { say "last?!?!" }
        QUIT { say "y u quit" }
    }
}

say "wat";
