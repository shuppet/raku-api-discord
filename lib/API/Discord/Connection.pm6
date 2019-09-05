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

    $c.closer.then({ say ":( $^a" });

    ... # other stuff

=head1 PROPERTIES

=end pod

use API::Discord::Types;
use API::Discord::HTTPResource;
# Probably make API::Discord::Connection::WS later for hb etc
use Cro::WebSocket::Client::Connection;
use Cro::HTTP::Client;

#| Websocket URL
has Str $.url is required;
#| User's bot/API token
has Str $.token is required;
#| Auto-populated from received websocket messages. Used to resume.
has Int $.sequence;
#| Auto-populated from received websocket messages. Used to resume.
has Str $.session-id;
#| Allows multiple instances to run the same bot
has Int $.shard = 0;
has Int $.shards-max = 1;

has Cro::WebSocket::Client::Connection $!websocket;
has Cro::HTTP::Client $!rest;
has Supplier $!messages;
has Supply $!heartbeat;
has Promise $!hb-ack;

#| This Promise will be kept if the websocket closes. See L<Cro::WebSocket::Client>
has Promise $.closer;

#| This Promise is kept when the websocket connects and is set up.
has Promise $.opener;

#| This Promise is kept when Discord has sent us a READY event
has Promise $.ready = Promise.new;

=begin pod

=head1 METHODS

=head2 new

Only C<$.url> and C<$.token> are required here.

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
    but RESTy["https://discordapp.com/api"];

    $!messages = Supplier::Preserving.new;

    self.connect();
}

# TODO: Make private
#| Connect to the websocket and handle the Promise. Returns the next Promise.
#| Can be called again, apparently.
method connect {
    my $cli = Cro::WebSocket::Client.new: :json;
    $!opener = $cli.connect($!url)
        .then( -> $connection {
            self._on_ws_connect($connection.result);
        });

}

# TODO: Make this private the p6 way not the p5 way
#| Handle websocket messages and set up the closer Promise.
method _on_ws_connect($!websocket) {
    my $messages = $!websocket.messages;
    $messages.tap:
        { self.handle-message($^a) }
    ;

    $!closer = $!websocket.closer.then(-> $closer {
        my $why = $closer.result;
        $!messages.done;
        $why;
    });
}

# TODO: Make private?
#| Text messages get checked for Discord-ness. Other messages... don't
method handle-message($m) {
    # FIXME - this creates a Promise that may be broken, and we do nothing
    # about that. It was suggested I use the supply pattern instead, but I'm
    # not sure how right now
    $m.body.then({ self.handle-opcode($^a.result) }) if $m.is-text;
    # else what?
}

# $json is JSON with an op in it
# TODO: Make private?
#| Deals with Discord messages and emits anything that the user might want to
#| know about.
method handle-opcode($json) {
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
            $!messages.emit($json);
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
            return if $!heartbeat;
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
            $!messages.emit($json);
        }
    }
}

#| Produce a regular Supply. We have to wait to do this because Discord tells us
#| what regularity to use. If Discord doesn't ack the heartbeat, we reconnect.
method setup-heartbeat($interval) {
    $!heartbeat = Supply.interval($interval);
    $!heartbeat.tap: {
        note "« ♥";
        $!websocket.send({
            d => $!sequence,
            op => OPCODE::heartbeat.Int,
        });

        # Set up a timeout that will be kept if the ack promise isn't
        $!hb-ack = Promise.new;
        Promise.anyof(
            Promise.in($interval), $!hb-ack
        ).then({
            return if $!hb-ack;
            note "Heartbeat wasn't acknowledged! ☹";
            note "Attempting to reconnect...";

            # TODO: Configurable number of reattempts before we just bail
            self.connect;
        });
    };
}

#| Prevents the panic stations we get when we don't hear back from the
#| heartbeat.
method ack-heartbeat-ack {
    note "» ♥";
    $!hb-ack.keep;
}

#| Resumes the session if there was one, or else sends the identify opcode.
method auth {
    if ($!session-id and $!sequence) {
        note "Resuming session $!session-id at sequence $!sequence";
        $!websocket.send({
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
    $!websocket.send({
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
method close {
    say "Closing connection";
    $!messages.done;
    #$!heartbeat.done;
    await $!websocket.close(code => 4001);
}

#| Gimme your REST client
method rest { $!rest }
