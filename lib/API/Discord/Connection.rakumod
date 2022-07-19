use API::Discord::Debug <FROM-MODULE>;
use API::Discord::Exceptions;
use API::Discord::HTTPResource;
use API::Discord::Types;
use API::Discord::WebSocket::Messages;
use API::Discord::WebSocket;
use Cro::HTTP::Client;

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

#| Websocket URL
has Str $.ws-url is required;
#| REST URL
has Str $.rest-url is required;
#| User's bot/API token
has Str $.token is required;
#| See discord docs on intents
has Int $.intents is required;
#| Allows multiple instances to run the same bot
has Int $.shard = 0;
has Int $.shards-max = 1;

#| The Cro HTTP client used for REST-y stuff.
has Cro::HTTP::Client $!rest;

#| The Discord WebSocket object, which parses raw WebSocket messages into Discord
#| messages, as well as handling protocol details such as sessions, sequences, and
#| heartbeats. There may be many connections over the lifetime of this object.
has API::Discord::WebSocket $!websocket .= new(
    :$!ws-url,
    :$!token,
    :$!intents,
);

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
}

#| A Supply of messages that are not handled by the protocol gubbins. When this is first
#| tapped, it begins listening on the WebSocket for messages, manages the protocol, and
#| so forth. Should there be a disconnect, a reconnect will be performed automatically.
method messages returns Supply {
    supply {
        debug-say("Making initial connection" but CONNECTION);
        connect();

        sub connect() {
            whenever $!websocket.connection-messages {
                when API::Discord::WebSocket::Event::Disconnected {
                    debug-say("Connection lost; establishing a new one" but CONNECTION);
                    connect();
                }
                when API::Discord::WebSocket::Event::Ready {
                    $!ready.keep unless $!ready;
                    proceed;
                }
                default {
                    emit .payload;
                }
            }
        }
    }
}

#| Gimme your REST client
method rest { $!rest }

