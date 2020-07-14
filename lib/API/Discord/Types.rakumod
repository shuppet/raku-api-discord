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
);


package ChannelType is export {
    enum :: <guild-text dm guild-voice group-dm guild-category> ;
}
