use API::Discord::Object;

unit class API::Discord::User does API::Discord::Object;
    # There's no update for others, but we consider @me an ID.

=begin pod

=head1 NAME

API::Discord::User - Represents Discord user

=head1 DESCRIPTION

Represents a Discord user, usually sent to use via the websocket. See
L<https://discordapp.com/developers/docs/resources/user>.

Users cannot be created or deleted.

=end pod

has @.dms;
has @.guilds;

has $.id;
has $.username;
has $.discriminator; # May start with 0 so we can't use int
has $.avatar;        # The actual image
has $.avatar-hash;   # The URL bit for the CDN
has $.is-bot;
has $.mfa-enabled;
has $.verified;
has $.email;

method to-json {}
method from-json ($json) {}
