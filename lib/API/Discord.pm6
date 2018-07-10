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

# Docs say, increment number each time, per process
has Int $!snowflake = 0;

submethod TWEAK {
    $!cli = Cro::WebSocket::Client.new: :json;
}

submethod DESTROY {
    $!conn.close;
}

method connect($session-id?, $sequence?) returns Promise {
    my $c = $!cli.connect("wss://{$.host}/?v={$.version}&encoding=json");

    return $c.then: -> $promise {
        my $cro-conn = $promise.result;
        $!conn = Connection.new(
            token => $.token,
            :$cro-conn,
          |(:$session-id if $session-id),
          |(:$sequence if $sequence),
        );

        $!conn.closer;
    };
}

method messages returns Supply {
    $!conn.messages;
}

multi method send-message(Hash $json) {
    $!conn.send({
        op => OPCODE::despatch,
        t => "MESSAGE_CREATE",
        d => $json,
    });
}

multi method send-message(Str :$message, Str :$to) {
    say "Send $message to $to";
    my $json = {
        tts => False,
        type => 0,
        channel_id => $to,
        content => $message,
        nonce => self.generate-snowflake,
        embed => {},
    };

    say "Sending " ~ $json;
    self.send-message($json);
}

method generate-snowflake {
    my $time = DateTime.now - DateTime.new(year => 2015);
    my $worker = 0;
    my $proc = 0;
    my $s = $!snowflake++;

    return ($time.Int +< 22) + ($worker +< 17) + ($proc +< 12) + $s;
}
