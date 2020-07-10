use API::Discord::Exceptions;
use API::Discord::Types;
use API::Discord::WebSocket::Messages;
use Cro::WebSocket::Client;

unit class API::Discord::WebSocket;

has $!ws-url is built is required;
has $!token is built is required;
has Cro::WebSocket::Client $!websocket .= new: :json;
has Supplier $!messages .= new;
has $!session-id is built;
has $!sequence is built;

# I tried to not need this but we have to ack it from the message handler, while
# the heartbeat itself is in a totally different scope
has $!hb-ack;

submethod TWEAK(--> Nil) {
    state $attempt-no = 0;
    $attempt-no++;

    my $conn = await $!websocket.connect($!ws-url);
    say "WS connected";

    $conn.closer.then: -> { note "Websocket closed :(" }
    start react whenever $conn.messages -> $m {
        whenever $m.body -> $json {
            if $json<s> {
                $!sequence = $json<s>;
            }

            my $payload = $json<d>;
            my $event = $json<t>;
            # mnemonic: rtfm

            given ($json<op>) {
                when OPCODE::dispatch {
                    if $event eq 'READY' {
                        $!session-id = $payload<session_id>;
                        $!messages.emit:
                                API::Discord::WebSocket::Event::Ready.new(payload => $json);
                    }
                    else {
                        $!messages.emit:
                                # TODO: pick the right class!
                                API::Discord::WebSocket::Event.new(payload => $json);
                    }
                }
                when OPCODE::invalid-session {
                    note "Session invalid. Refreshing.";
                    $!session-id = Str;
                    $!sequence = Int;
                    # Docs say to wait a random amount of time between 1 and 5
                    # seconds, then re-auth
                    Promise.in(4.rand + 1).then({ self!auth($conn) });
                }
                when OPCODE::hello {
                    self!auth($conn);
                    self!setup-heartbeat($conn, $payload<heartbeat_interval> / 1000);
                }
                when OPCODE::reconnect {
                    note "reconnect";
                    $!messages.emit:
                            API::Discord::WebSocket::Event::Disconnected.new(payload => $json,
                            session-id => $!session-id, last-sequence-number => $!sequence,);
                    note "Stopping message handler $attempt-no";
                    done;
                }
                when OPCODE::heartbeat-ack {
                    self!ack-heartbeat-ack;
                }
                default {
                    note "Unhandled opcode $_ ({ OPCODE($_) })";
                    $!messages.emit: API::Discord::WebSocket::Event.new(payload => $json);
                }
            }
        }
    }
}

method !setup-heartbeat($websocket, $interval) {
    my $hb = supply {
        $!hb-ack = Nil;
        whenever Supply.interval($interval) {
            if not $!hb-ack.defined or $!hb-ack {
                $!hb-ack = Promise.new;
                emit $_;
            }
            else {
                X::API::Discord::Connection::Flatline.new.throw
            }
        }
    };

    start react {
        whenever $hb {
            $*ERR.print: "« ♥";
            $websocket.send({
                d => $!sequence,
                op => OPCODE::heartbeat.Int,
            });

            QUIT {
                when X::API::Discord::Connection::Flatline {
                    $*ERR.print: "💔! 🔌…";
                    $!messages.emit:
                        API::Discord::WebSocket::Event::Disconnected.new(
                            session-id => $!session-id,
                            last-sequence-number => $!sequence,
                        );
                    done;
                }
            }
        }

        whenever $websocket.closer {
            done
        }
    }
}

#| Prevents the panic stations we get when we don't hear back from the
#| heartbeat.
method !ack-heartbeat-ack {
    $*ERR.print: "♥ » ";
    $!hb-ack.keep;
}


#| Resumes the session if there was one, or else sends the identify opcode.
method !auth($websocket) {
    note "Auth...";
    if ($!session-id and $!sequence) {
        note "Resuming session $!session-id at sequence $!sequence";
        $websocket.send({
            op => OPCODE::resume.Int,
            d => {
                token => $!token,
                session_id => $!session-id,
                sequence => $!sequence,
            }
        });
        return;
    }

    # TODO: There is a gateway bot bootstrap endpoint that tells you things like
    # how many shards to use. We should investigate this
    note "New session...";
    $websocket.send({
        op => OPCODE::identify.Int,
        d => {
            token => $!token,
            properties => {
                '$os' => $*PERL.Str,
                '$browser' => 'API::Discord',
                '$device' => 'API::Discord',
            },
            shard => [0,1]
        }
    });
}

method messages returns Supply {
    $!messages.Supply
}
