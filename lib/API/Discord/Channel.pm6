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

has $.id;
has @.messages;

method fetch-messages(Int $how-many) {
    ...
}
