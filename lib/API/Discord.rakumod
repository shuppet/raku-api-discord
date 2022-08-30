use API::Discord::Connection;
use API::Discord::HTTPResource;
use API::Discord::Intents;

use API::Discord::Channel;
use API::Discord::Guild;
use API::Discord::Message;
use API::Discord::User;
use API::Discord::Debug <FROM-MODULE>;

use Cro::WebSocket::Client;
use Cro::WebSocket::Client::Connection;

unit class API::Discord is export;

=begin pod

=head1 NAME

API::Discord - Perl6 interface to L<Discord|https://discordapp.com> API

=head1 DESCRIPTION

This provides a lowish-level interface to the Discord API. It supplies a stream
of messages and other events to which your app can listen.

=head1 SYNOPSIS

    use API::Discord;
    use API::Discord::Debug; # remove to disable debug output

    my $d = API::Discord.new(:token(my-bot-token), :script-mode);

    $d.connect;
    await $d.ready;

    react {
        whenever $d.messages -> $m {
            ...
        }

        # Events not yet implemented
        #whenever $d.events -> $e {
        #    ...
        #}
    }

=head1 USING OBJECTS

API::Discord models the various API objects in corresponding classes. These
classes can either be used directly, or used via the API object. The API object
has the advantage of also having connections to Discord, thus allowing you to
fetch and send data without doing it manually.

Most of the time, you will want to use an existing object to create and send
another object.

For example, Discord communicates with us which Guilds and Channels we are in,
so the API constantly keeps a cache of these, since they are usually few and
rarely change. Therefore, to create a Channel, you might do it via Guild, and to
send a Message, you might do it via Channel.

Channel and Guild are usually your entrypoints to doing things.

    $api.get-channel($id).send-message("Hi I'm a bot");
    $api.get-guild($id).create-channel({ ... });

The other entrypoint to information are the message and event supplies. These
emit complete objects, which can be used to perform further actions. For
example, the Message class stores the Channel from which it came, and Channel
has send-message:

    whenever $api.messages -> $m {
        $m.channel.send-message("I heard that!");
    }

All of these classes use the API to fetch and send if they need to. This
prevents them from having to know about one another, which would result in
circular dependencies. It also makes them easier to test N<If we ever did that>.

Ultimately, you can always just create and send an object to Discord if you want
to do it that way.

    my $m = API::Discord::Message.new(...);
    $api.send($m);

This requires you to know all the parts you need for the operation to be
successful, however.

=head2 CRUD

The core of the Discord API is simple CRUD mechanics over REST. The general idea
in API::Discord is that if an object has an ID, then C<send> will update it;
otherwise, it will create it and populate the ID from the response.

This way, the same few methods handle most of the interaction you will have with
Discord: editing a message is done by calling C<send> with a Message object that
already has an ID; whereas posting a new message would simply be calling C<send>
with a message with no ID, but of course a channel ID instead.

API::Discord also handles deflating your objects into JSON. The structures
defined by the Discord docs are supported recursively, which means if you set an
object on another object, the inner object will also be deflated—into the
correct JSON property—to be sent along with the outer object. However, if the
Discord API doesn't support that structure in a particular situation, it just
won't try to do it.

For example, you can set an Embed on a Message and just send the Message, and
this will serialise the Embed and send that too.

    my $m = API::Discord::Message.new(:channel($channel));
    $m.embed(...);

    API::Discord.send($m);

This example will serialise the Message and the Embed and send them, but will
not attempt to serialise the entire Channel object into the Message object
because that is not supported. Instead, it will take the channel ID from the
Channel object and put that in the expected place.

Naturally, one cannot delete an object with no ID, just as one cannot attempt to
read an object given anything but an ID. (Searching notwithstanding.)

=head1 SHARDING

Discord implements sharding but you have to set it up yourself. This allows you
to run multiple processes to handle data.

To do so, pass a value for C<shard> and a value for C<shards-max> in each
process. You have to know how many processes you are running altogether. To add
a shard, it is therefore necessary to restart all of your existing shards;
otherwise, it would suddenly change which process is handling data for which
guild.

Remember that only shard 0 will receive DMs.

By default, the connection will assume you have only one shard.

=head1 PROPERTIES

=head2 script-mode

This is a fake boolean property. If set, we handle SIGINT for you and disconnect
properly.

=end pod

has Connection $!conn;

#| The API version to use. I suppose we should try to keep this up to date.
has Int $.version = 10;
#| Host to which to connect. Can be overridden for testing e.g.
has Str $.ws-host = 'gateway.discord.gg';
#| Host for REST requests
has Str $.rest-host = 'discord.com';
#| Host for CDN URLs. This is gonna change eventually.
has Str $.cdn-url = 'https://cdn.discordapp.com';
#| Bot token or whatever, used for auth.
has Str $.token is required;
#| Shard number for this connection
has Int $.shard = 0;
#| Number of shards you're running
has Int $.shards-max = 1;
#| Bitmask of intents
has Int $.intents = ([+|] guilds, guild-messages, guild-message-reactions, message-content);

# Docs say, increment number each time, per process
has Int $!snowflake = 0;

has Supplier $!messages = Supplier.new;

has Supplier $!events = Supplier.new;

#| Our user, populated on READY event
has $.user is rw;

#| A hash of Channel objects, keyed by the Channel ID.
has %.channels;

#| A hash of Guild objects that the user is a member of, keyed by the Guild ID. B<TODO> Currently this is not populated.
has %.guilds;

# Kept when all guild IDs we expect to receive have been received. TODO: timeout
has Promise $!guilds-ready = Promise.new;

method new (*%args) {
    my $script-mode = %args<script-mode>:delete;

    my $self = callwith |%args;

    if $script-mode {
        signal(SIGINT).tap: {
            await $self.disconnect;
            debug-say "Bye! 👋";
            exit;
        }
    }

    return $self;
}

method !handle-message($message) {
    # TODO - send me an object please
    if $message<t> eq 'GUILD_CREATE' {
        for $message<d><channels><> -> $c {
            $c<guild_id> = $message<d><id>;
            my $id = $c<id>;
            my $chan = Channel.new( id => $id, api => self, real => Channel.reify( $c, self ) );
            %.channels{$id} = $chan;
        }

        %.guilds{$message<d><id>} = self.inflate-guild($message<d>);

        # TODO: We might never get all of the guilds in the READY event. Set up
        # a timeout to keep it.
        if [&&] map *.defined, %.guilds.values {
            debug-say "All guilds ready!";
            $!guilds-ready.keep unless $!guilds-ready;
        }
    }
    elsif $message<t> eq 'READY' {
        $.user = self.inflate-user(%(
            |$message<d><user>,
            id => '@me',
            real-id => $message<d><user><id>
        ));

        # Initialise empty objects for later.
        %.guilds{$_<id>} = Any for $message<d><guilds><>;
    }
}

#| Disconnects gracefully. Remember to await it!
method disconnect {
    $!conn.close;
}

#| Connects to discord. Await the L</ready> Promise, then tap $.messages and $.events
method connect($session-id?, $sequence?) returns Promise {
    $!conn = Connection.new(
        ws-url => "wss://{$.ws-host}/?v={$.version}&encoding=json",
        rest-url => "https://{$.rest-host}/api",
        :$.token,
        :$.shard,
        :$.shards-max,
        :$.intents,
      |(:$session-id if $session-id),
      |(:$sequence if $sequence),
    );

    start react whenever $!conn.messages -> $message {
        self!handle-message($message);
        if $message<t> eq 'MESSAGE_CREATE' {
            my $m = self.inflate-message($message<d>);

            $!messages.emit($m)
                unless $message<d><author><id> == $.user.real-id;
        }
        else {
            $!events.emit($message);
        }
    }
}

#| Proxies the READY promise on connection. Await this before communicating with
#discord.
method ready returns Promise {
    Promise.allof($!conn.ready, $!guilds-ready);
}

#| Emits a Message object whenever a message is received. B<TODO> Currently this emits hashes.
method messages returns Supply {
    $!messages.Supply;
}
#| A Supplier that emits things that aren't messages. B<TODO> Implement this
method events returns Supply {
    $!events.Supply;
}

#| Creates an integer using the snowflake algorithm, guaranteed unique probably.
method generate-snowflake {
    my $time = DateTime.now - DateTime.new(year => 2015);
    my $worker = 0;
    my $proc = 0;
    my $s = $!snowflake++;

    return ($time.Int +< 22) + ($worker +< 17) + ($proc +< 12) + $s;
}

method rest { $!conn.rest }

=begin pod
=head3 Factories and fetchers

C<inflate-> and C<create-> methods return the object directly because they do
not involve communication. All the other methods return a Promise that resolve
to the documented return value.

=end pod

#| See also get-message(s) on the Channel class.
method get-message (Any:D $channel-id, Any:D $id) returns Message {
    Message.new(:$channel-id, :$id, _api => self);
}

method get-messages (Any:D $channel-id, Any:D @message-ids) returns Array {
    @message-ids.map: self.get-message($channel-id, *);
}

method inflate-message (%json) returns Message {
    Message.new(
        api => self,
        id => %json<id>,
        channel-id => %json<channel_id>,
        real => Message.reify( %json )
    );
}

method create-message (%params) returns Message {
    Message.new(
        api => self,
        |%params
    );
}

method get-channel (Any:D $id) returns Channel {
    %.channels{$id} //= Channel.new( id => $id, api => self );
}

method get-channels (Any:D @channel-ids) returns Array {
    @channel-ids.map: self.get-channel(*);
}

method inflate-channel (%json) returns Channel {
    Channel.new(
        api => self,
        id => %json<id>,
        real => Channel.reify( %json, self )
    );
}

method create-channel (%params) returns Channel {
    Channel.new(|%params, api => self);
}

method get-guild (Any:D $id) returns Guild {
    %.guilds{$id} //= Guild.new(id => $id, _api => self)
}

method get-guilds (Any:D @guild-ids) returns Array {
    @guild-ids.map: self.get-guild(*);
}

method inflate-guild (%json) returns Guild {
    Guild.new(
        api => self,
        id => %json<id>,
        real => Guild.reify( %json )
    );
}

method create-guild (%params) returns Guild {
    Guild.new(|%params, api => self);
}

method get-user (Any:D $id) returns User {
    User.new(id => $id, api => self);
}

method get-users (Any:D @user-ids) returns Array {
    @user-ids.map: self.get-user(*);
}

method inflate-user (%json) returns User {
    User.new(
        api => self,
        id => %json<id>,
        real-id => %json<real-id>,
        real => User.reify( %json, self )
    );
}

method create-user (%params) returns User {
    User.new(|%params, api => self);
}

# TODO
method inflate-member(%json) returns Guild::Member {
    Guild::Member.from-json(%(|%json, _api => self));
}
