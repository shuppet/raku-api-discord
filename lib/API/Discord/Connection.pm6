use API::Discord::Exceptions;
use API::Discord::WebSocket::Messages;
use API::Discord::WebSocket;

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
use Cro::HTTP::Client;

#| Websocket URL
has Str $.ws-url is required;
#| REST URL
has Str $.rest-url is required;
#| User's bot/API token
has Str $.token is required;
#| Allows multiple instances to run the same bot
has Int $.shard = 0;
has Int $.shards-max = 1;

has Cro::HTTP::Client $!rest;
has Supplier $!message-source .= new;
has Supply $!messages = $!message-source.Supply.migrate;
has Promise $!hb-ack;

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
    my $websocket = API::Discord::WebSocket.new(ws-url => $!ws-url, token => $!token);
    note "Done";

    $!message-source.emit: supply {
        whenever $websocket.messages -> $m {
            given $m {
                when API::Discord::WebSocket::Event::Ready {
                    $!ready.keep;
                }
                when API::Discord::WebSocket::Event::Disconnected {
                    self.connect;
                }

                emit $m.payload
            }
        }
    };
}

#| Wow, a public method! Tap this to receive messages we didn't handle as part
#| of the protocol gubbins.
method messages returns Supply {
    $!messages;
}

#| Gimme your REST client
method rest { $!rest }

