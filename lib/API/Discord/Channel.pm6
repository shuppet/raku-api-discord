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
has $.rate-limit-per-user;
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
            my $e = endpoint-for( self, 'pinned-messages' ) ;
            my $p = await $.api.rest.get($e);
            @pins = (await $p.body).map( { $!api.inflate-message($_) } );
            @pins;
        }
    }

    $!fetch-pins-promise;
}

#| Sends a message to the channel and returns the POST promise.
method send-message($content) {
    $.api.create-message({
        channel-id => $.id,
        :$content
    }).create;
}

method pin($message) returns Promise {
    $.api.rest.touch(endpoint-for(self, 'pinned-message', message-id => $message.id));
}

method unpin($message) returns Promise {
    $.api.rest.remove(endpoint-for(self, 'pinned-message', message-id => $message.id));
}

#| Shows the "user is typing..." message to everyone in the channel. Disappears
#| after ~10 seconds or when a message is sent.
method trigger-typing {
    # TODO: Handle error
    $.api.rest.post(endpoint-for(self, 'trigger-typing'));
}

#| Deletes these messages. Max 100, minimum 2. If any message does not belong to
#| this channel, the whole operation fails. Returns a promise that resolves to
#| the new message array.
method bulk-delete(@messages) {
    start {
        # TODO: I don't think we're handling a failure from this correctly
        await $.api.rest.post(endpoint-for(self, 'bulk-delete'), messages => @messages.map: *.id);

        my %antipairs{Any} = @!messages.antipairs;
        my @removed-idxs = %antipairs{@messages};
        my \to-remove = set(@removed-idxs);
        my @keep = @!messages.keys.grep(none(to-remove));
        @!messages = @!messages[@keep];
    }
}

method to-json {
    # We're only allowed to update a subset of the fields we receive.
    my %self := self.Capture.hash;

    my %json = %self<position bitrate name topic icon>:kv;
    %json<nsfw rate_limit_per_user user_limit parent_id> = %self<is-nsfw rate-limit-per-user user-limit parent-id>;
    # TODO: permission overwrites

    return %json
}

method from-json($json) {
    my %constructor = $json<id position bitrate name topic icon>:kv;
    %constructor<api> = $json<_api>;
    #%constructor<type> = ChannelType($json<type>.Int);
    %constructor<
        guild-id last-message-id rate-limit-per-user
        owner-id application-id parent-id is-nsfw user-limit>
    = $json<
        guild_id last_message_id rate_limit_per_user
        owner_id application_id parent_id nsfw user_limit>;

    %constructor<last-pin-timestamp> = DateTime.new($json<last_pin_timestamp>)
        if $json<last_pin_timestamp>;

    # TODO: permission overwrites
    return self.new(|%constructor);
}
