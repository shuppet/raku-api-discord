use API::Discord::Object;

unit class API::Discord::Channel does API::Discord::Object;

has %.ENDPOINTS is readonly =
    create => '/channels',
    read => '/channels/{id}',
    update => '/channels/{id}',
    delete => '/channels/{id}',

    get-messages => '/channels/{id}/messages',
    bulk-delete-messages => '/channels/{id}/messages/bulk-delete',

    edit-permissions => '/channels/{id}/permissions/{overwrite-id}',
    delete-permission => '/channels/{id}/permissions/{overwrite-id}',

    get-invites => '/channels/{id}/invites',
    create-invite => '/channels/{id}/invites',

    trigger-typing => '/channels/{id}/typing',

    get-pinned-messages => '/channels/{id}/pins',
    add-pinned-message => '/channels/{id}/pins/{message-id}',
    delete-pinned-message => '/channels/{id}/pins/{message-id}',

    add-group-recipient => '/channels/{id}/recipients/{user-id}',
    remove-group-recipient => '/channels/{id}/recipients/{user-id}',
;

enum ChannelType ();

has $.id;
has ChannelType $.type;
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

method to-json {}

method from-json($json) {
    my %constructor = $json<id position bitrate name topic icon>:kv;
    #%constructor<type> = ChannelType($json<type>.Int);
    %constructor<guild-id last-message-id user-limit owner-id application-id parent-id is-nsfw>
        = $json<guild_id last_message_id user_limit owner_id application_id parent_id nsfw>;

    %constructor<last-pin-timestamp> = DateTime.new($json<last_pin_timestamp>)
        if $json<last_pin_timestamp>;

    return self.new(|%constructor);
}
