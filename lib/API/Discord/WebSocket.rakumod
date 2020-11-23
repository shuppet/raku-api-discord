use API::Discord::Exceptions;
use API::Discord::Types;
use API::Discord::WebSocket::Messages;
use Cro::WebSocket::Client;
use API::Discord::Debug <FROM-MODULE>;

unit class API::Discord::WebSocket;

#| The WebSocket URL to connect to.
has $!ws-url is built is required;

#| The access token.
has $!token is built is required;

#| A bitmask, all the way from the user
has $!intents is built is required;

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
    debug-say("WS connected" but WEBSOCKET);
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
                        debug-say("Session invalid. Refreshing." but WEBSOCKET);
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
                        debug-say("reconnect" but WEBSOCKET);
                        emit API::Discord::WebSocket::Event::Disconnected.new(payload => $json,
                                        session-id => $!session-id, last-sequence-number => $!sequence,);
                        debug-say "Stopping message handler $!attempt-no";
                        done;
                    }
                    when OPCODE::heartbeat-ack {
                        debug-print("♥ » " but PONG);
                        $heartbeat-acknowledged = True;
                    }
                    default {
                        debug-say("Unhandled opcode $_ ({ OPCODE($_) })" but WEBSOCKET);
                        emit API::Discord::WebSocket::Event.new(payload => $json);
                    }
                }
            }
        }

        whenever $conn.closer -> $close {
            my $blob = await $close.body-blob;
            my $code = $blob.read-uint16(0, LittleEndian);

            debug-say("Websocket closed :( ($code)" but WEBSOCKET);
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
                        debug-say('heartbeat lost' but HEARTBEAT);
                        emit API::Discord::WebSocket::Event::Disconnected.new:
                                session-id => $!session-id,
                                last-sequence-number => $!sequence;
                        $conn.close;
                        done;
                    }
                }

                # Send heartbeat and set that we're awaiting an acknowledgement.
                debug-print("« ♥" but PONG);
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
    debug-say("Auth..." but WEBSOCKET);
    if ($!session-id and $!sequence) {
        debug-say "Resuming session $!session-id at sequence $!sequence";
        $websocket.send({
            op => OPCODE::resume.Int,
            d => {
                token => $!token,
                session_id => $!session-id,
                seq => $!sequence,
            }
        });
        return;
    }

    # TODO: There is a gateway bot bootstrap endpoint that tells you things like
    # how many shards to use. We should investigate this
    debug-say("New session..." but WEBSOCKET);
    $websocket.send({
        op => OPCODE::identify.Int,
        d => {
            token => $!token,
            properties => {
                '$os' => $*PERL.Str,
                '$browser' => 'API::Discord',
                '$device' => 'API::Discord',
            },
            shard => [0,1],
            intents => $!intents,
        }
    });
}
