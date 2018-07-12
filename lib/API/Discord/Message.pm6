unit class API::Discord::Message does API::Discord::HTTPMessage;

class Activity {
    enum Type (
        0 => 'join',
        2 => 'spectate',
        3 => 'listen',
        5 => 'join-request',
    );

    has Type $.type;
    has $.party-id;
}

enum Type (
    <default recipient-add> ...
);

# TODO : Endpoint type
has %.ENDPOINTS is readonly =
    create => '/channels/{channel-id}/messages',
;

has $.id;
has $.channel-id;
has API::Discord::Channel $.channel;
has API::Discord::User $.author;

has API::Discord::Reaction @.reactions;
has Type $.type;

...; # Rest of properties

submethod TWEAK {
    $!channel = API::Discord::Channel.new($!channel-id);
}

method from-json { ... }
method to-json { ... }
