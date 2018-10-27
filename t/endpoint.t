use API::Discord::Endpoints;
use API::Discord::Message;
use Test;

throws-like {
    my $m = Message.new(:channel-id(1));
    endpoint-for($m, 'read');
}, X::API::Discord::Endpoint::NotEnoughArguments, message => / 'channel-id id'/;

{
    my $m = Message.new(:channel-id(1234));
    is endpoint-for($m, 'create'), '/channels/1234/messages', "Got correct URL";
}

{
    my $m = Message.new(:channel-id(1234));
    is endpoint-for($m, 'read', id => 123), '/channels/1234/messages/123', "Got correct URL";
}

done-testing;
