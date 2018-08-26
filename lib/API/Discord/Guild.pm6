use API::Discord::Object;

unit class API::Discord::Guild does API::Discord::Object;

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

#! See L<Api::Discord::JSONy>
method to-json {}
#! See L<Api::Discord::JSONy>
method from-json ($json) {}
