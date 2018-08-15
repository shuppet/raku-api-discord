use API::Discord::Object;

unit class API::Discord::User does API::Discord::Object;
    # There's no update for others, but we consider @me an ID.

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

has @.dms;
has @.guilds;

has $.id;
has $.username;
has $.discriminator; # May start with 0 so we can't use int
has $.avatar;        # The actual image
has $.avatar-hash;   # The URL bit for the CDN
has $.is-bot;
has $.mfa-enabled;
has $.verified;
has $.email;

method to-json {}
method from-json ($json) {}
