unit class API::Discord::Guild does API::Discord::HTTPMessage;

has %.ENDPOINTS is readonly =
    create => '/guilds',
    read => '/guilds/{guild-id}',
    update => '/guilds/{guild-id}',
    delete => '/guilds/{guild-id}',

    get-channels => '/guilds/{guild-id}/channels',
    create-channel => '/guilds/{guild-id}/channels',

    get-member => '/guilds/{guild-id}/members/{user-id}',
    list-members => '/guilds/{guild-id}/members',
    add-member => '/guilds/{guild-id}/members/{user-id}',
    modify-member => '/guilds/{guild-id}/members/{user-id}',
    remove-member => '/guilds/{guild-id}/members/{user-id}',

    get-bans => '/guilds/{guild-id}/bans',
    create-ban => '/guilds/{guild-id}/bans/{user-id}',
    revoke-ban => '/guilds/{guild-id}/bans/{user-id}',

    get-prune-count => '/guilds/{guild-id}/prune',
    begin-prune => '/guilds/{guild-id}/prune',

    get-integrations => '/guilds/{guild-id}/integrations',
    create-integration => '/guilds/{guild-id}/integrations',
    modify-integration => '/guilds/{guild-id}/integrations/{integration-id}',
    delete-integration => '/guilds/{guild-id}/integrations/{integration-id}',
    sync-integration => '/guilds/{guild-id}/integrations/{integration-id}/sync',

    get-embed => '/guilds/{guild-id}/embed',
    modify-embed => '/guilds/{guild-id}/embed',

    modify-nick => '/guilds/{guild-id}/members/@me/nick',
    get-invites => '/guilds/{guild-id}/invites',
    get-voice-regions => '/guilds/{guild-id}/regions',
    vanity-url => '/guilds/{guild-id}/vanity-url',
;

