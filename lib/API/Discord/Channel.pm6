unit class API::Discord::Channel does API::Discord::HTTPMessage;

has %.ENDPOINTS is readonly =
    create => '/channels',
    read => '/channels/{channel-id}',
    update => '/channels/{channel-id}',
    delete => '/channels/{channel-id}',

    get-messages => '/channels/{channel-id}/messages',
;

has API::Discord::Message @.messages;
