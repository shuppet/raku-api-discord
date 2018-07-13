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

has %.ENDPOINTS is readonly =
    create => '/channels/{channel-id}/messages',
    read => '/channels/{channel-id}/messages/{message-id}',
    update => '/channels/{channel-id}/messages/{message-id}',
    delete => '/channels/{channel-id}/messages/{message-id}',

    get-reactions =>  '/channels/{channel-id}/messages/{message-id}/reactions'
;

has $.id;
has $.channel-id;
has API::Discord::Channel $.channel;# will lazy { API::Discord::Channel.new($.channel-id) };
has API::Discord::User $.author;

has API::Discord::Reaction @.reactions;
has Type $.type;

...; # Rest of properties

submethod TWEAK {
    if $!channel.defined {
        $!channel-id = $!channel.id
    }
    elsif not $!channel-id.defined {
        die "Must provide channel or channel-id";
    }
}

method from-json { ... }
method to-json { ... }
