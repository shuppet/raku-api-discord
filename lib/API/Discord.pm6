use Cro::WebSocket::Client;
use Cro::WebSocket::Client::Connection;

class API::Discord::Connection {...}

class API::Discord is export {
    has Cro::WebSocket::Client $!cli;

    has $.version = 6;

    method connect() returns Promise {
        $!cli = Cro::WebSocket::Client.new: :json;

        my $c = $!cli.connect("wss://gateway.discord.gg/?v={$.version}&encoding=json");

        my $p = Promise.new;
        $c.then({ $p.keep(API::Discord::Connection.new(cro-conn => $^a)) });

        return $p;
    }
}

class API::Discord::Connection is export {
    has Cro::WebSocket::Client::Connection $!cro-conn;
    has $!token;

    submethod TWEAK() {
        # setup heartbeat
    }

    method auth ($token?) {
        $!token = $token if $token;

        die "No token" if not $!token;

        $!cro-conn.send({
            op => 2,
            d => {
                token => $!token,
                properties => {
                    '$os' => $*PERL,
                    '$browser' => 'API::Discord',
                    '$device' => 'API::Discord',
                }
            }
        });
    }
}
