use API::Discord::Exceptions;

unit class API::Discord::Connection;

=begin pod

=head1 NAME

API::Discord::Connection - Combines a websocket and a REST client

=head1 DESCRIPTION

Discord sends us information over the websocket, and we send it stuff over the
REST client. Mostly.

This is used internally and probably of limited use otherwise.

=head1 SYNOPSIS

    my $c = API::Discord::Connection.new:
        :url(wss://...),
        :$token,
    ;


    ... # other stuff

=head1 PROPERTIES

=end pod

use API::Discord::Types;
use API::Discord::HTTPResource;
# Probably make API::Discord::Connection::WS later for hb etc
use Cro::WebSocket::Client::Connection;
use Cro::HTTP::Client;

#| Websocket URL
has Str $.ws-url is required;
#| REST URL
has Str $.rest-url is required;
#| User's bot/API token
has Str $.token is required;
#| Auto-populated from received websocket messages. Used to resume.
has Int $.sequence;
#| Auto-populated from received websocket messages. Used to resume.
has Str $.session-id;
#| Allows multiple instances to run the same bot
has Int $.shard = 0;
has Int $.shards-max = 1;

has Cro::HTTP::Client $!rest;
has Supplier $!messages .= new;
has Promise $!hb-ack;

#| Will be kept upon disconnection. May be before or after the websocket closes.
has Promise $.closer = Promise.new;

#| This Promise is kept when the websocket connects and is set up.
has Promise $.opener;

#| This Promise is kept when Discord has sent us a READY event
has Promise $.ready = Promise.new;

=begin pod

=head1 METHODS

=head2 new

C<$.ws-url>, C<$.rest-url> and C<$.token> are required here.

=end pod

submethod TWEAK {
    # TODO: We should also take the user-agent URL and the REST URL as
    # constructor parameters
    $!rest = Cro::HTTP::Client.new(
        content-type => 'application/json',
        http => '1.1',
        headers => [
            Authorization => 'Bot ' ~ $!token,
            User-agent => "DiscordBot (https://github.io/shuppet/p6-api-discord, 0.0.1)",
            Accept => 'application/json, */*',
            Connection => 'keep-alive',
        ]
    )
    but RESTy[$!rest-url];

    self.connect();
}

# TODO: Make private
#| Connect to the websocket and handle the Promise. Returns the next Promise.
#| Can be called again, apparently.
method connect {
    note "New websocket connection...";
    my $cli = Cro::WebSocket::Client.new: :json;
    note "Done";
    $!opener = $cli.connect($!ws-url)
        .then( -> $connection {
            self!on_ws_connect($connection.result);
        });

}

method !on_ws_connect($websocket) {
    $!closer = Promise.new;
    $websocket.closer.then({ $!closer.keep if not $!closer });
    # I made this a supply {} but I realised that it is not a supply; emitting
    # messages is one of the things we do, but not the only thing we do.
    start react { note "Starting message handler"; whenever $websocket.messages -> $m {
        my $json = $m.body.result;

        if $json<s> {
            $!sequence = $json<s>;
        }

        my $payload = $json<d>;
        my $event = $json<t>; # mnemonic: rtfm

        given ($json<op>) {
            when OPCODE::dispatch {
                if $event eq 'READY' {
                    $!session-id = $payload<session_id>;
                    $!ready.keep;
                }
                $!messages.emit: $json;
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
                self.auth($websocket);
                self.setup-heartbeat($websocket, $payload<heartbeat_interval>/1000);
            }
            when OPCODE::reconnect {
                note "reconnect";
                self.close($websocket);
                note "connect ... ";
                self.connect;
                note "Stopping message handler";
                done;
            }
            when OPCODE::heartbeat-ack {
                self.ack-heartbeat-ack;
            }
            default {
                note "Unhandled opcode $_ ({OPCODE($_)})";
                $!messages.emit: $json;
            }
        }
    }}
}

method heartbeat($interval --> Supply) {
    supply {
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

        whenever $!closer { done }
    }
}

method setup-heartbeat($websocket, $interval) {
    start react whenever self.heartbeat($interval) {
        $*ERR.print: "« ♥";
        $websocket.send({
            d => $!sequence,
            op => OPCODE::heartbeat.Int,
        });

        QUIT {
            when X::API::Discord::Connection::Flatline {
                $*ERR.print: "💔! 🔌…";
                self.close($websocket);
                self.connect;
                done;
            }
        }
    };
}

#| Prevents the panic stations we get when we don't hear back from the
#| heartbeat.
method ack-heartbeat-ack {
    $*ERR.print: "♥ » ";
    $!hb-ack.keep;
}

#| Resumes the session if there was one, or else sends the identify opcode.
method auth($websocket) {
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
    $websocket.send({
        op => OPCODE::identify.Int,
        d => {
            token => $!token,
            properties => {
                '$os' => $*PERL.Str,
                '$browser' => 'API::Discord',
                '$device' => 'API::Discord',
            },
            shard => [ $.shard, $.shards-max ]
        }
    });
}

#| Wow, a public method! Tap this to receive messages we didn't handle as part
#| of the protocol gubbins.
method messages returns Supply {
    $!messages.Supply;
}

#| Call this to close the connection, I guess. We don't really use it.
method close($websocket) {
    say "Closing connection";
    $!sequence = Nil;
    $!session-id = Nil;
    $!closer.keep;
    $websocket.close(code => 4001);
    note "closed";
}

#| Gimme your REST client
method rest { $!rest }
