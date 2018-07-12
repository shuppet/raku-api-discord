use Cro::HTTP::Client;
use API::Discord::Endpoints;
unit class API::Discord::Connection::REST is Cro::HTTP::Client;

has $.version = '6';
has $.base-url = "https://discordapp.com/api";

# multi method send (API::Discord::HTTPMessage $m) {
#    $m.create(self)
# }
multi method send(API::Discord::Message $m) {
    $m.create(self);
}

multi method send(Str $endpoint, Hash $json) {
    my $c = $json<channel_id>:delete;
    my $e = endpoint-for('message', 'post', :channel-id($c));

    say "Send $json to $.base-url$e";

    self.post: "$.base-url$e", body => $json;
}
