unit class API::Discord is export;

#use Timer::Breakable;
use API::Discord::Types;
use Cro::WebSocket::Client;
use Cro::WebSocket::Client::Connection;

class Connection {...}

has Cro::WebSocket::Client $!cli;

has Connection $!conn;
# Although a number it goes in a URL so it's a string
has Str $.version = '6';
has Str $.token is required;

submethod TWEAK {
    $!cli = Cro::WebSocket::Client.new: :json;

}

submethod DESTROY {
    $!conn.close;
}

method connect($session-id?, $sequence?) returns Promise {
    my $c = $!cli.connect("wss://gateway.discord.gg/?v={$.version}&encoding=json");

    return $c.then: {
        $!conn = Connection.new(
            token => $.token,
            cro-conn => $^a.result,
          |(:$session-id if $session-id),
          |(:$sequence if $sequence),
        );

        # Attempt to reconnect when disconnected.
        # I don't think I can reuse this connection if that happens.
        $^a.result.closer.then({
            self.connect($!conn.session-id, $!conn.sequence);
        });
    };
}

method messages returns Supply {
    $!conn.messages;
}

class Connection {
    has Cro::WebSocket::Client::Connection $.cro-conn is required;
    has Str $.token is required;
    has Int $.sequence;
    has Str $.session-id;
    has Supply $.messages;
    has Supply $!heartbeat;
    has Promise $!hb-ack;

    submethod TWEAK {
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

        my $payload = $json<d>;
        say $json<op t>;
        given ($json<op>) {
            when OPCODE::despatch {
                # TODO: check event!
                $!session-id = $payload<session_id>;

                # These are probably useful to the bot
                # We will figure out any that might not be, and handle them
                # here in future
                say "emit {$json<t>}";
                $.messages.emit($json);
            }
            when OPCODE::invalid-session {
                note "Session invalid. Refreshing.";
                $!session-id = Str;
                $!sequence = Int;
                # Docs say to wait a random amount of time between 1 and 5
                # seconds, then re-auth
                Promise.in(4.rand+1).then({ self.auth });
            }
            when OPCODE::hello {
                self.auth;
                self.setup-heartbeat($payload<heartbeat_interval>/1000);
            }
            when OPCODE::reconnect {
                self.auth;
            }
            when OPCODE::heartbeat-ack {
                self.ack-heartbeat-ack;
            }
            default {
                note "Unhandled opcode $_ ({OPCODE($_)})";
                $.messages.emit($json);
            }
        }
    }

    method setup-heartbeat($interval) {
        $!heartbeat = Supply.interval($interval);
        $!heartbeat.tap: {
            note "♥";
            $!cro-conn.send({
                d => $!sequence,
                op => OPCODE::heartbeat,
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

    method ack-heartbeat-ack {
        note "Still with us ♥";
        $!hb-ack.keep;
    }

    method auth {
        if ($!session-id and $!sequence) {
        }

        $!cro-conn.send({
            op => OPCODE::identify,
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

    method close {
        $.messages.done;
        $!cro-conn.close;
    }
}
