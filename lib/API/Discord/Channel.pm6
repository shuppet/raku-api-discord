use API::Discord::Object;

unit class API::Discord::Channel does API::Discord::Object is export;

package ChannelType {
    enum :: <guild-text dm guild-voice group-dm guild-category> ;
}

has $.id;
has $.type;
has $.guild-id;
has $.position;
has $.name;
has $.topic;
has $.is-nsfw;
has $.last-message-id;
has $.bitrate;
has $.user-limit;
has $.icon;
has $.owner-id;
has $.application-id;
has $.parent-id;
has DateTime $.last-pin-timestamp;

has $.parent-category;
has $.owner;
has @.recipients;
has @.permission-overwrites;
has @.messages;


method fetch-messages(Int $how-many) {
}

method send-message(Str $content) {
    $.api.create-message(
        channel-id => $.id,
        :$content
    ).create;
}

method to-json {}

method from-json($json) {
    my %constructor = $json<id position bitrate name topic icon>:kv;
    %constructor<api> = $json<_api>;
    #%constructor<type> = ChannelType($json<type>.Int);
    %constructor<guild-id last-message-id user-limit owner-id application-id parent-id is-nsfw>
        = $json<guild_id last_message_id user_limit owner_id application_id parent_id nsfw>;

    %constructor<last-pin-timestamp> = DateTime.new($json<last_pin_timestamp>)
        if $json<last_pin_timestamp>;

    return self.new(|%constructor);
}
