unit module API::Discord::Types;

subset Snowflake is export of Str where /^ <[ 0 1 ]> ** 64 $/;

enum OPCODE is export (
    <dispatch heartbeat identify status-update
    voice-state-update voice-ping
    resume reconnect
    request-members
    invalid-session hello heartbeat-ack>
);

enum CLOSE-EVENT is export (
    4000 => 'Unknown error',
    4001 => 'Unknown opcode',
    4002 => 'Decode error',
    4003 => 'Not authenticated',
    4004 => 'Authentication failed',
    4005 => 'Already authenticated',
    4007 => 'Invalid seq',
    4008 => 'Rate limited',
    4009 => 'Session timed out',
    4010 => 'Invalid shard',
    4011 => 'Sharding required',
    4012 => 'Invalid API version',
    4013 => 'Invalid intent(s)',
    4014 => 'Disallowed intent(s)',
);

enum INTENT is export (
    guilds                  => 1 +< 0,
    guild-members           => 1 +< 1,
    guild-bans              => 1 +< 2,
    guild-emojis            => 1 +< 3,
    guild-integrations      => 1 +< 4,
    guild-webhooks          => 1 +< 5,
    guild-invites           => 1 +< 6,
    guild-voice-states      => 1 +< 7,
    guild-presences         => 1 +< 8,
    guild-messages          => 1 +< 9,
    guild-message-reactions => 1 +< 10,
    guild-message-typing    => 1 +< 11,
    direct-messages         => 1 +< 12,
    direct-message-reactions=> 1 +< 13,
    direct-message-typing   => 1 +< 14,
);

package ChannelType is export {
    enum :: <guild-text dm guild-voice group-dm guild-category guild-news guild-store> ;
}
