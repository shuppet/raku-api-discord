use Cro::HTTP::Client;
use API::Discord::Endpoints;
use API::Discord::HTTPResource;

unit class API::Discord::Connection::REST is Cro::HTTP::Client does RESTy;

has $.version = '6';
has $.base-url = "https://discordapp.com/api";

multi method send (API::Discord::HTTPResource $m) {
    $m.create(self)
}
#multi method send(API::Discord::Message $m) {
#    $m.create(self);
#}

