use API::Discord::Object;

unit class API::Discord::Guild is API::Discord::Object;

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
    audit-log => '/guilds/{guild-id}/audit-logs',
    vanity-url => '/guilds/{guild-id}/vanity-url',
;

has Int  $.id;
has Str  $.name;
has Str  $.icon;
has Str  $.splash;
has Bool $.is-owner;
has Int  $.owner-id;
has Int  $.permissions;
has Str  $.region;
has Int  $.afk-channel-id;
has Int  $.afk-channel-timeout;
has Bool $.is-embeddable;
has Int  $.embed-channel-id;
has Int  $.verification-level;
has Int  $.default-notification-level;
has Int  $.content-filter-level;
has Int  $.mfa-level-required;
has Int  $.application-id;
has Bool $.is-widget-enabled;
has Int  $.widget-channel-id;
has Int  $.system-channel-id;
has DateTime $.joined-at;
has Bool $.is-large;
has Bool $.is-unavailable;
has Int  $.member-count;

has @.roles;
has @.emojis;
has @.features;
has @.voice-states;
has @.members;
has @.channels;
has @.presences;

enum MessageNotificationLevel (
    <all-messages only-mentions>
);

enum ContentFilterLevel (
    <disabled members-without-roles all-members>
);

enum MFALevel (
    <none elevated>
);

enum VerificationLevel (
    <none low medium high very-high>
);
