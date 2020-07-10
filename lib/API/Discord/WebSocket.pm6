use API::Discord::Exceptions;
use API::Discord::Types;
use API::Discord::WebSocket::Messages;
use Cro::WebSocket::Client;

unit class API::Discord::WebSocket;

#| The WebSocket URL to connect to.
has $!ws-url is built is required;

#| The access token.
has $!token is built is required;

#| The Cro WebSocket client used for the connection.
has Cro::WebSocket::Client $!websocket .= new: :json;

#| Session ID, set so long as we have a valid/active session.
has Str $!session-id;

#| The current sequence number, used so we can recover missed messages upon resumption of
#| an existing session.
has Int $!sequence;

#| The number of connection attempts we have made.
has Int $!attempt-no = 0;

#| Establishes a new connection, resuming the session if applicable. Returns a Supply of the
#| messages emitted on the connection, and is done when the connection ends for some reason
#| (disconnect of some kind or heartbeat not acknowledged).
method connection-messages(--> Supply) {
    $!attempt-no++;
    my $conn = await $!websocket.connect($!ws-url);
    say "WS connected";
    return supply {
        # Set to false when we send a heartbeat, and to true when the heartbeat is acknowledged. If
        # we don't get an acknowledgement then we know something is wrong.
        my Bool $heartbeat-acknowledged;

        whenever $conn.messages -> $m {
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
                            emit API::Discord::WebSocket::Event::Ready.new(payload => $json);
                        }
                        else {
                            # TODO: pick the right class!
                            emit API::Discord::WebSocket::Event.new(payload => $json);
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
                        start-heartbeat($payload<heartbeat_interval> / 1000);
                    }
                    when OPCODE::reconnect {
                        note "reconnect";
                        emit API::Discord::WebSocket::Event::Disconnected.new(payload => $json,
                                        session-id => $!session-id, last-sequence-number => $!sequence,);
                        note "Stopping message handler $!attempt-no";
                        done;
                    }
                    when OPCODE::heartbeat-ack {
                        $*ERR.print: "♥ » ";
                        $heartbeat-acknowledged = True;
                    }
                    default {
                        note "Unhandled opcode $_ ({ OPCODE($_) })";
                        emit API::Discord::WebSocket::Event.new(payload => $json);
                    }
                }
            }
        }

        whenever $conn.closer {
            note "Websocket closed :(";
            emit API::Discord::WebSocket::Event::Disconnected.new:
                    session-id => $!session-id,
                    last-sequence-number => $!sequence;
            done;
        }

        sub start-heartbeat($interval) {
            whenever Supply.interval($interval) {
                # Handle missing acknowledgements.
                with $heartbeat-acknowledged {
                    unless $heartbeat-acknowledged {
                        $*ERR.print: "💔! 🔌…";
                        emit API::Discord::WebSocket::Event::Disconnected.new:
                                session-id => $!session-id,
                                last-sequence-number => $!sequence;
                        $conn.close;
                        done;
                    }
                }

                # Send heartbeat and set that we're awaiting an acknowledgement.
                $*ERR.print: "« ♥";
                $conn.send({
                    d => $!sequence,
                    op => OPCODE::heartbeat.Int,
                });
                $heartbeat-acknowledged = False;
            }
        }
    }
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
