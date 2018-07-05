use Cro::WebSocket::Client;
use Cro::WebSocket::Client::Connection;

class API::Discord::Connection {...}

class API::Discord is export {
    has Cro::WebSocket::Client $!cli;

    has $.version = 6;
    has $.token is required;

    method connect() returns Promise {
        $!cli = Cro::WebSocket::Client.new: :json;

        my $c = $!cli.connect("wss://gateway.discord.gg/?v={$.version}&encoding=json");

        return $c.then: {
            API::Discord::Connection.new(
                token => $.token,
                cro-conn => $^a.result
            )
        };
    }
}

class API::Discord::Connection is export {
    has Cro::WebSocket::Client::Connection $.cro-conn is required;
    has $.token is required;
    has $!sequence;

    submethod TWEAK() {
        my $messages = $!cro-conn.messages;
        $messages.tap:
            { self.handle-message($^a) },
            done => { self.auth() }
        ;
    }

    method handle-message($m) {
        $m.body.then({ self.handle-opcode($^a) }) if $m.is-text;
        # else what?
    }

    # $json is JSON with an op in it
    method handle-opcode($json) {
        if $json<s> {
            $!sequence = $json<s>;
        }
        given ($json<op>) {
            when 10 {
                self.auth;
#                self.setup-heartbeat;
            }
            when 11 {
#                self.ack-heartbeat-ack;
            }
            default {
                #$!supply.emit($json);
            }
        }
    }

    method auth () {
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
