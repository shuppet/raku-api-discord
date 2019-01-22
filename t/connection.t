# vim: setf perl6

use API::Discord;
use Cro::HTTP::Server;
use Cro::HTTP::Router;
use Cro::HTTP::Router::WebSocket;
use Test;

my $app = route {
    get -> :$v, :$encoding {
        web-socket -> $incoming {
            supply {
                whenever $incoming -> $req {
                    say $v; say $encoding; say $req
                }
            }
        }
    }

    get -> 'api' {
        request-body -> %json-object {
            %json-object.say
        }
    }
}

my $http-server = Cro::HTTP::Server.new(port => 3005, application => $app);
$http-server.start();
END { $http-server.stop() };

my $discord = API::Discord.new(
    ws-url => 'ws://localhost:3005',
    rest-url => 'http://localhost:3005/api',
    token => 'testtoken',
);

await $discord.connect;

react {
    whenever $discord.messages -> $message {
        $message.say
    }
}
