use API::Discord::Object;
use API::Discord::Endpoints;

unit class API::Discord::Channel does API::Discord::Object is export;

=begin pod

=head1 NAME

API::Discord::Channel - Represents a channel or DM

=head1 DESCRIPTION

Represents a channel in a guild, or a pseudo-channel used for direct messages. 

See also L<API::Discord::Messages>.

=head1 CONSTANTS

=head2 API::Discord::Channel::ChannelType

Contains values for the C<type> property

    guild-text dm guild-voice group-dm guild-category

=head1 MESSAGES

Messages are handled differently from many other things in this API because they
are constantly changing. The API will update each channel with messages as they
arrive.

The messages are therefore stored in the C<@.messages> array, the first item of
which will be the most recent message. The array may change at any time, so you
should refer to it directly rather than saving a copy if you want the most
recent facts.

No historical messages are getch at the point of construction; the array will
merely track messages as they arrive. Use L<fetch-messages> to append historical
messages to the array.

=end pod

package ChannelType {
    enum :: <guild-text dm guild-voice group-dm guild-category> ;
}

has $.id;
has $.type;
has $.guild-id;
has $.position;
has $.name;
has $.topic;
has $.is-nsfw;
has $.last-message-id;
has $.bitrate;
has $.user-limit;
has $.icon;
has $.owner-id;
has $.application-id;
has $.parent-id;
has DateTime $.last-pin-timestamp;

has $.parent-category;
has $.owner;
has @.recipients;
has @.permission-overwrites;
has @.messages;

has Promise $!fetch-message-promise;
has Promise $!fetch-pins-promise;

submethod TWEAK() {
    # Seed the promise for fetch-messages to chain from
    $!fetch-message-promise = start {};
}

#| Fetch N messages and returns a Promise that resolves to the complete new list
#| of messages. If something is already fetching messages, your call will await
#| those before making its own call on top of them.
#| TODO: maybe only fetch enough extra messages after that one?
method fetch-messages(Int $how-many) returns Promise {
    $!fetch-message-promise = $!fetch-message-promise.then: {
        my $get = 'get-messages';
        if @.messages {
            $get ~= '?after=' ~ @.messages[*-1].id;
        }
        my $e = endpoint-for(self, $get);
        my $p = await $.api.rest.get($e);

        @.messages.push: (await $p.body).map: { $.api.inflate-message($_) };
        @.messages;
    };
}

#| Returns all pinned messages at once, in a Promise
method pinned-messages($force?) returns Promise {
    if $force or not $!fetch-pins-promise {
        $!fetch-pins-promise = start {
            my @pins;
            my $e = endpoint-for( self, 'get-guilds' ) ;
            my $p = await $.api.rest.get($e);
            @pins = (await $p.body).map( { $!api.inflate-message($_) } );
            @pins;
        }
    }

    $!fetch-pins-promise;
}

#| Sends a message to the channel and returns the POST promise.
method send-message(Str $content) {
    $.api.create-message({
        channel-id => $.id,
        :$content
    }).create;
}

#| Shows the "user is typing..." message to everyone in the channel. Disappears
#| after ~10 seconds or when a message is sent.
method trigger-typing {
    # TODO: Handle error
    $.api.rest.post(endpoint-for(self, 'trigger-typing'));
}

method to-json {}

method from-json($json) {
    my %constructor = $json<id position bitrate name topic icon>:kv;
    %constructor<api> = $json<_api>;
    #%constructor<type> = ChannelType($json<type>.Int);
    %constructor<guild-id last-message-id user-limit owner-id application-id parent-id is-nsfw>
        = $json<guild_id last_message_id user_limit owner_id application_id parent_id nsfw>;

    %constructor<last-pin-timestamp> = DateTime.new($json<last_pin_timestamp>)
        if $json<last_pin_timestamp>;

    return self.new(|%constructor);
}
