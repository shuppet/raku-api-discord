use API::Discord::HTTPResource;

unit class API::Discord::Channel does HTTPResource;
class API::Discord::Message {...};

has %.ENDPOINTS is readonly =
    create => '/channels',
    read => '/channels/{channel-id}',
    update => '/channels/{channel-id}',
    delete => '/channels/{channel-id}',

    get-messages => '/channels/{channel-id}/messages',
    bulk-delete-messages => '/channels/{channel-id}/messages/bulk-delete',

    edit-permissions => '/channels/{channel-id}/permissions/{overwrite-id}',
    delete-permission => '/channels/{channel-id}/permissions/{overwrite-id}',

    get-invites => '/channels/{channel-id}/invites',
    create-invite => '/channels/{channel-id}/invites',

    trigger-typing => '/channels/{channel-id}/typing',

    get-pinned-messages => '/channels/{channel-id}/pins',
    add-pinned-message => '/channels/{channel-id}/pins/{message-id}',
    delete-pinned-message => '/channels/{channel-id}/pins/{message-id}',

    add-group-recipient => '/channels/{channel-id}/recipients/{user-id}',
    remove-group-recipient => '/channels/{channel-id}/recipients/{user-id}',
;

has API::Discord::Message @.messages;

method fetch-messages(Int $how-many) {
    ...
}
