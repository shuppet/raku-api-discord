unit class API::Discord::User does API::Discord::HTTPMessage;

has %.ENDPOINTS =
    read => '/users/{user-id}',
    update => '/users/{user-id}',

    get-guilds => '/users/{user-id}/guilds',
    leave-guild => '/users/{user-id}/guilds',

    get-dms => '/users/{user-id}/channels',
    create-dm => '/users/{user-id}/channels',

    # This is OAuth2 stuff, so we probably won't use it
    get-connections => '/users/{user-id}/connections'
;

has API::Discord::Channel @.dms;
has API::Discord::Guild @.guilds;

has Int  $.id;
has Str  $.username;
has Str  $.discriminator; # May start with 0 so we can't use int
has Blob $.avatar;        # The actual image
has Str  $.avatar-hash;   # The URL bit for the CDN
has Bool $.is-bot;
has Bool $.mfa-enabled;
has Bool $.verified;
has Str  $.email;
