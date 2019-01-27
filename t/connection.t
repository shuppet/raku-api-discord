# vim: setf perl6

use API::Discord;
use API::Discord::Types;
use Cro::HTTP::Server;
use Cro::HTTP::Router;
use Cro::HTTP::Router::WebSocket;
use Cro::WebSocket::Message;
use Test;

my $server-send-message = Supplier.new;
my $app = route {
    get -> :$v, :$encoding {
        web-socket
            :body-parsers(Cro::WebSocket::BodyParser::JSON),
            :body-serializers(Cro::WebSocket::BodySerializer::JSON),
        -> $recv {
            supply {
                whenever $recv -> $inc {
                    my $json = $inc.body.result;
                    given $json<op> {
                        when OPCODE::heartbeat {
                            $server-send-message.emit({
                                op => OPCODE::heartbeat-ack,
                            });
                        }
                        when OPCODE::identify {
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

await $discord.connect;
$server-send-message.emit({
    op => OPCODE::hello,
    d => {
        heartbeat_interval => 1000
    }
});
react {
    whenever $discord.messages -> $message {
        say "awoo";
    }
}
