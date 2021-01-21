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

package ChannelType is export {
    enum :: <guild-text dm guild-voice group-dm guild-category guild-news guild-store> ;
}
