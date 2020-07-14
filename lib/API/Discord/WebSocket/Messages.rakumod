class API::Discord::WebSocket::Event {
    enum OPERATION (
        <create update delete>
    );

    has OPERATION $.operation;
    has $.payload;
}

class API::Discord::WebSocket::Event::Message
is API::Discord::WebSocket::Event {}
class API::Discord::WebSocket::Event::Message::Reaction
is API::Discord::WebSocket::Event {}

class API::Discord::WebSocket::Event::Guild
is API::Discord::WebSocket::Event {}
class API::Discord::WebSocket::Event::Guild::Member
is API::Discord::WebSocket::Event {}

class API::Discord::WebSocket::Event::Channel
is API::Discord::WebSocket::Event {}

class API::Discord::WebSocket::Event::Typing
is API::Discord::WebSocket::Event {}
class API::Discord::WebSocket::Event::Presence
is API::Discord::WebSocket::Event {}

class API::Discord::WebSocket::Event::Disconnected
is API::Discord::WebSocket::Event {
    has $.session-id;
    has $.last-sequence-number;
}

class API::Discord::WebSocket::Event::Ready
is API::Discord::WebSocket::Event {}
