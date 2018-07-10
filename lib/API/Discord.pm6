unit class API::Discord is export;

#use Timer::Breakable;
use API::Discord::Types;
use API::Discord::Connection;
use Cro::WebSocket::Client;
use Cro::WebSocket::Client::Connection;

has Connection $!conn;
# Although a number it goes in a URL so it's a string
has Str $.version = '6';
has Str $.host = 'gateway.discord.gg';
has Str $.token is required;

# Docs say, increment number each time, per process
has Int $!snowflake = 0;

submethod DESTROY {
    $!conn.close;
}

method connect($session-id?, $sequence?) returns Promise {
    $!conn = Connection.new(
        url => "wss://{$.host}/?v={$.version}&encoding=json",
        token => $.token,
      |(:$session-id if $session-id),
      |(:$sequence if $sequence),
    );

    return $!conn.opener.then({ $!conn.closer });
}

method messages returns Supply {
    $!conn.messages;
}

multi method send-message(Str :$message, Str :$to) {
    my $json = {
        tts => False,
        type => 0,
        channel_id => $to,
        content => $message,
        nonce => self.generate-snowflake,
        embed => {},
    };

    $!conn.send($json);
}

method generate-snowflake {
    my $time = DateTime.now - DateTime.new(year => 2015);
    my $worker = 0;
    my $proc = 0;
    my $s = $!snowflake++;

    return ($time.Int +< 22) + ($worker +< 17) + ($proc +< 12) + $s;
}
