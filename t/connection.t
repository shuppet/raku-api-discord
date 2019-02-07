# vim: setf perl6

use API::Discord;
use API::Discord::Types;
use Cro::HTTP::Server;
use Cro::HTTP::Router;
use Cro::HTTP::Router::WebSocket;
use Cro::WebSocket::Message;
use Test;

my $server-send-message = Supplier.new;
my $server-receive-message = Supplier.new;

my %tests = 
    :!connected,
    :!identified,
    heartbeats => {
        expected => 0,
        received => 0,
    }
;
my $app = route {
    get -> :$v, :$encoding {
        web-socket
            :body-parsers(Cro::WebSocket::BodyParser::JSON),
            :body-serializers(Cro::WebSocket::BodySerializer::JSON),
        -> $recv {
            %tests<connected> = True;
            supply {
                whenever $recv -> $inc {
                    my $json = $inc.body.result;
                    $server-receive-message.emit($json);
                    given $json<op> {
                        when OPCODE::heartbeat {
                            %tests<heartbeats><received>++;
                            $server-send-message.emit({
                                op => OPCODE::heartbeat-ack,
                            });
                        }
                        when OPCODE::identify {
                            %tests<identified> = True;
                        }
                        default {
                            die "Attempted to send to websocket";
                        }
                    }
                }
                whenever $server-send-message -> $message {
                    $message.emit;
                }
            }
        }
    }

    get -> 'api' {
        request-body -> %json-object {
            %json-object.say
        }
    }
};

my $http-server = Cro::HTTP::Server.new(port => 3005, application => $app);
$http-server.start();
END { $http-server.stop() };

my $discord = API::Discord.new(
    ws-url => 'ws://localhost:3005',
    rest-url => 'http://localhost:3005/api',
    token => 'testtoken',
);

my $heartbeat-interval = 1000;
Supply.interval($heartbeat-interval/1000).tap: { %tests<heartbeats><expected>++ };
await $discord.connect;
$server-send-message.emit({
    op => OPCODE::hello,
    d => {
        heartbeat_interval => $heartbeat-interval
    }
});

# Remember to wait a bit longer for the final hb
sleep 3.1;

ok %tests<connected>, "Connected";
ok %tests<identified>, "Identified";
ok $_<expected> == $_<received>, "Heartbeats correct" given %tests<heartbeats>;

%tests.say;
