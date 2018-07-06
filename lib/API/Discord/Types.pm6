unit module API::Discord::Types;


enum OPCODE is export (
    <despatch heartbeat identify status-update
    voice-state-update voice-ping
    resume reconnect
    request-members
    invalid-session hello heartbeat-ack>
);

enum CLOSE-EVENT is export (
    
)

