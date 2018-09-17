use API::Discord::Object;
use URI::Encode;

unit class API::Discord::Message does API::Discord::Object is export;

=begin pod

=head1 NAME

API::Discord::Message - Represents Discord message

=head1 DESCRIPTION

Represents a Discord message in a slightly tidier way than raw JSON. See
L<https://discordapp.com/developers/docs/resources/channel#message-object>,
unless it moves.

Messages are usually created when the websocket sends us one. Each is associated
with a Channel object.

=head1 TYPES

=end pod

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

class Reaction does API::Discord::Object {
    # This class is special because a) only Message uses it and b) it doesn't
    # use the default HTTP logic when sending.
    has $.emoji;
    has $.count;
    has $.i-reacted;
    has $.user;

    has $.message;

    method self-send(Str $endpoint, $resty) returns Promise {
        $resty.put: "$endpoint", body => {};
    }
    method from-json($json) {
        # We added message because only the Message class calls this
        self.new(|$json);
    }

    method to-json { {} }
}

enum Type (
    <default recipient-add>
);

=head1 PROPERTIES

=begin pod

=head2 JSON fields

See L<API::Discord::Object> for JSON fields discussion

    < id channel-id nonce content is-tts mentions-everyone is-pinned webhook-id
    mentions-role-ids type timestamp edited >

=end pod

has $.id;
has $.channel-id;
has $.nonce;
has $.content;
has $.is-tts;
has $.mentions-everyone;
has $.is-pinned;
has $.webhook-id;
has @.mentions-role-ids;
has $.type;

has DateTime $.timestamp;
has DateTime $.edited;

=begin pod
=head2 Object accessors

See L<API::Discord::Object> for Object properties discussion

    < channel author mentions mentions-roles attachments embeds reactions >

=end pod

has $.author;
has @.mentions;
has @.mentions-roles; # will lazy { ... }
has @.attachments;
has @.embeds;
# TODO: perhaps this should be emoji => count and we don't need the Reaction class.
# (We can use Emoji objects as the keys if we want)
has @.reactions;

# TODO
#has API::Discord::Activity $.activity;
#has API::Discord::Application $.application;

=begin pod
=head1 METHODS

=head2 new

A Message can be constructed by providing any combination of the JSON accessors.

If any of the object accessors are set, the corresponding ID(s) in the JSON set
will be set, even if you passed that in too.

This ensures that they will be consistent, at least until you break it on
purpose.

=end pod

#| Returns a Promise that resolves to the channel.
method channel {
    $.api.get-channel($.channel-id)
}

method add-reaction(Str $e is copy) {
    $e = uri_encode_component($e) unless $e ~~ /\:/;
    Reaction.new(:emoji($e), :user('@me'), :message(self)).create($.api.rest);
}

#| Inflates the Message object from the JSON we get from Discord
method from-json (%json) returns ::?CLASS {
    # These keys we can lift straight out
    my %constructor = %json<id nonce content type>:kv;

    # These keys we sanitized for nice Perl6 people
    %constructor<channel-id is-tts mentions-everyone is-pinned webhook-id mentions-role-ids>
        = %json<channel_id tts mention_everyone pinned webhook_id mention_roles>;

    # These keys we can trivially inflate.
    %constructor<timestamp> = DateTime.new(%json<timestamp>);
    %constructor<edited> = DateTime.new(%json<edited_timestamp>) if %json<edited_timestamp>;

    # These keys represent another level of data structure and are related
    # objects, which should have their own from-json. However, we're not going
    # to go and fetch related objects that are provided by ID; only ones that we
    # already have the data for.
# TODO: Decide where these factories should go, and then use them.
#    %constructor<author> = $.api.User.from-json($json<author>);
#    %constructor<mentions> = $json<mentions>.map: $.api.create-user($_);
#    %constructor<attachments> = $json<attachments>.map: self.create-attachment($_);
#    %constructor<embeds> = $json<embeds>.map: self.create-embed($_);
#    %constructor<reactions> = $json<reactions>.map: self.create-reaction($_);

    %constructor<api> = %json<_api>;
    return self.new(|%constructor);
}

#| Deflates the object back to JSON to send to Discord
method to-json returns Hash {
    my %self := self.Capture.hash;
    my %json = %self<id nonce content type timestamp>:kv;
    %json<edited_timestamp> = $_ with %self<edited>;

    %json<channel_id tts mention_everyone pinned webhook_id mention_roles>
        = %self<channel-id is-tts mentions-everyone is-pinned webhook-id mentions-role-ids>;

    $.author andthen %json<author> = .to-json;

    for <mentions attachments embeds reactions> -> $prop {
        %self{$prop} andthen %json{$prop} = [map *.to-json, $_.values]
    }

    return %json;
}
