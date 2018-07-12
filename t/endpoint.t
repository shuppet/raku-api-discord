use API::Discord::Endpoints;
use Test;

throws-like {
    endpoint-for('message', 'post');
}, X::API::Discord::Endpoint::NotEnoughArguments;

throws-like {
    endpoint-for('message', 'get');
}, X::API::Discord::Endpoint::NotEnoughArguments, message => / 'channel-id message-id'/;

is endpoint-for('message', 'post', channel-id => 1234), '/channels/1234/messages', "Got correct URL";
