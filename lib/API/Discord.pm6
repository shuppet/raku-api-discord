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
    has Supply $.messages;
    has Supply $!heartbeat;
    has Promise $!hb-ack;

    submethod TWEAK() {
        my $messages = $!cro-conn.messages;
        $messages.tap:
            { self.handle-message($^a) },
            done => { self.auth() }
        ;

        my $supplier = Supplier::Preserving.new;
        $!messages = $supplier.Supply;
    }

    method handle-message($m) {
        $m.body.then({ self.handle-opcode($^a.result) }) if $m.is-text;
        # else what?
    }

    # $json is JSON with an op in it
    method handle-opcode($json) {
        if $json<s> {
            $!sequence = $json<s>;
        }
        say $json;
        given ($json<op>) {
            when 10 {
                self.auth;
                self.setup-heartbeat($json<d><heartbeat_interval>/1000);
            }
            when 11 {
                self.ack-heartbeat-ack;
            }
            default {
                $.messages.emit($json);
            }
        }
    }

    method setup-heartbeat($interval) {
        $!heartbeat = Supply.interval($interval);
        $!heartbeat.tap: {
            note "♥ $interval";
            $!cro-conn.send({
                d => $!sequence,
                op => 1,
            });

            # Set up a timeout that will be kept if the ack promise isn't
            $!hb-ack = Promise.new;
            Promise.anyof(
                Promise.in($interval), $!hb-ack
            ).then({
                return if $!hb-ack;
                note "Heartbeat wasn't acknowledged! ☹";
                self.close;
            });
        };
    }

    method ack-heartbeat-ack() {
        note "Still with us ♥";
        $!hb-ack.keep;
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

    method close() {
        $.messages.done;
        $!cro-conn.close;
    }
}
