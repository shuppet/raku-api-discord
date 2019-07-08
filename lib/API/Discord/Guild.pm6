use API::Discord::Object;
use API::Discord::Endpoints;

unit class API::Discord::Guild does API::Discord::Object is export;

=begin pod

=head1 NAME

API::Discord::Guild - Colloquially known as a server

=head1 DESCRIPTION

Defines a guild, or server, slightly adapting the JSON object defined in the
documentation at L<https://discordapp.com/developers/docs/resources/guild>.

Guilds are usually created by the websocket layer, as a result of the bot user
being added to the guild. However, the Discord documentation does allow for
guilds to be fetched or created via the API in some circumstances. Knowing
whether or not you can do this is up to the user; you can always try.

=end pod

class Member { ... };

enum MessageNotificationLevel (
    <notification-all-messages notification-only-mentions>
);

enum ContentFilterLevel (
    <filter-disabled filter-members-without-roles filter-all-members>
);

enum MFALevel (
    <mfa-none mfa-elevated>
);

enum VerificationLevel (
    <verification-none verification-low verification-medium verification-high verification-very-high>
);

=head1 PROPERTIES

=begin pod
=head2 JSON fields

See L<API::Discord::Object> for JSON fields discussion

    < id name icon splash is-owner owner-id permissions region afk-channel-id
    afk-channel-timeout is-embeddable embed-channel-id verification-level
    default-notification-level content-filter-level mfa-level-required
    application-id is-widget-enabled widget-channel-id system-channel-id joined-at
    is-large is-unavailable member-count >

=end pod

has $.id;
has $.name;
has $.icon;
has $.splash;
has $.is-owner;
has $.owner-id;
has $.permissions;
has $.region;
has $.afk-channel-id;
has $.afk-channel-timeout;
has $.is-embeddable;
has $.embed-channel-id;
has $.verification-level;
has $.default-notification-level;
has $.content-filter-level;
has $.mfa-level-required;
has $.application-id;
has $.is-widget-enabled;
has $.widget-channel-id;
has $.system-channel-id;
has DateTime $.joined-at;
has $.is-large;
has $.is-unavailable;
has $.member-count;

=begin pod
=head2 Object properties

See L<API::Discord::Object> for Object properties discussion

    < roles emojis features voice-states members channels presences >

=end pod

has @.roles;
has @.emojis;
has @.features;
has @.voice-states;
has @.members;
has @.channels;
has @.presences;

method assign-role($user, *@role-ids) {
    start {
        my $member = self.get-member($user);

        $member<roles>.append: @role-ids;

        await self.update-member($user, { roles => $member<roles> });
    }

}

method unassign-role($user, *@role-ids) {
    start {
        my $member = self.get-member($user);

        $member<roles> = $member<roles>.grep: @role-ids !~~ *;
        say $member;

        await self.update-member($user, { roles => $member<roles> });
    }
}

multi method get-member(API::Discord::Object $user) returns Member {
    samewith($user.id);
}

multi method get-member(Int $user-id) returns Member {
    my $e = endpoint-for( self, 'get-member', :$user-id );
    my $member = $.api.rest.get($e).result.body.result;
    $.api.inflate-member($member);
}

multi method update-member(API::Discord::Object $user, %new-data) returns Promise {
    samewith($user.id, %new-data);
}

multi method update-member(Int $user-id, %new-data) returns Promise {
    my $e = endpoint-for( self, 'get-member', :$user-id );
    $.api.rest.patch($e, body => %new-data)
}

multi method remove-member(API::Discord::Object $user) returns Promise {
    samewith($user.id);
}

multi method remove-member(Int $user-id) returns Promise {
    my $e = endpoint-for( self, 'remove-member', :$user-id );
    return $.api.rest.delete($e);
}

#! See L<Api::Discord::JSONy>
method to-json {
    my %self = self.Capture.hash;
    my %json = %self<id name icon splash>:kv;

    %json<owner> = %self<is-owner>;

    return %json;
}

#! See L<Api::Discord::JSONy>
method from-json (%json) {
    my %constructor = %json<id name icon splash>:kv;
    %constructor<is-owner> = %json<owner>;

    %constructor<api> = %json<_api>;
    return self.new(|%constructor);
}

class Member does API::Discord::Object {
    has $.guild;
    has $.user;
    has $.nick;
    has Bool $.is-owner;
    has @.roles;
    has DateTime $.joined-at;
    has DateTime $.premium-since;
    has Bool $.is-deaf;
    has Bool $.is-mute;

    method from-json(%json) {
        my %constructor = %json<nick roles>:kv;
        my $api = %json<_api>;

        %constructor<is-owner is-deaf is-mute> = %json<deaf mute>;

        %constructor<guild> = $api.inflate-guild(%json<guild>);
        %constructor<user> = $.api.inflate-user(%json<user>);
        %constructor<owner> = %constructor<guild>.owner_id == %constructor<user>.id;

        %constructor<joined-at> = DateTime.new(%json<joined_at>);
        %constructor<premium-since> = DateTime.new(%json<premium_since>);

        return self.new(|%constructor, api => $api);
    }
}
