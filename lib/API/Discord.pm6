unit class API::Discord is export;

#use Timer::Breakable;
use API::Discord::Types;
use API::Discord::Connection;
use Cro::WebSocket::Client;
use Cro::WebSocket::Client::Connection;

has Cro::WebSocket::Client $!cli;

has Connection $!conn;
# Although a number it goes in a URL so it's a string
has Str $.version = '6';
has Str $.host = 'gateway.discord.gg';
has Str $.token is required;

submethod TWEAK {
    $!cli = Cro::WebSocket::Client.new: :json;

}

submethod DESTROY {
    $!conn.close;
}

method connect($session-id?, $sequence?) returns Promise {
    my $c = $!cli.connect("wss://{$.host}/?v={$.version}&encoding=json");

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

