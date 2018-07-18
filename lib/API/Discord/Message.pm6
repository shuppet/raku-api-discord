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

class Reaction {
}

enum Type (
    <default recipient-add> ...
);

has %.ENDPOINTS is readonly =
    create => '/channels/{channel-id}/messages',
    read => '/channels/{channel-id}/messages/{message-id}',
    update => '/channels/{channel-id}/messages/{message-id}',
    delete => '/channels/{channel-id}/messages/{message-id}',
;

has Int  $.id;
has Int  $.channel-id;
has Int  $.nonce;
has Str  $.content;
has Bool $.is-tts;
has Bool $.mentions-everyone;
has Bool $.is-pinned;
has Int  $.webhook-id;
has Int  @.mentions-role-ids;
has Type $.type;

has DateTime $.timestamp;
has DateTime $.edited;

has API::Discord::Channel $.channel;# will lazy { API::Discord::Channel.new($.channel-id) };
has API::Discord::User $.author;
has API::Discord::User @.mentions;
has API::Discord::Role @.mentions-roles; # will lazy { ... }
has API::Discord::Attachment @.attachments;
has API::Discord::Embed @.embeds;
# TODO: perhaps this should be emoji => count and we don't need the Reaction class.
# (We can use Emoji objects as the keys if we want)
has Reaction @.reactions;

# TODO
#has API::Discord::Activity $.activity;
#has API::Discord::Application $.application;


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
