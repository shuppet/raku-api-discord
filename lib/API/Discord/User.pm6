use API::Discord::Object;
use API::Discord::Endpoints;

unit class API::Discord::User does API::Discord::Object is export;
    # There's no update for others, but we consider @me an ID.

=begin pod

=head1 NAME

API::Discord::User - Represents Discord user

=head1 DESCRIPTION

Represents a Discord user, usually sent to use via the websocket. See
L<https://discordapp.com/developers/docs/resources/user>.

Users cannot be created or deleted.

=end pod

has @!dms;
has @!guilds;

has $.id;
has $.username;
has $.discriminator; # May start with 0 so we can't use int
has $.avatar;        # The actual image
has $.avatar-hash;   # The URL bit for the CDN
has $.is-bot;
has $.is-mfa-enabled;
has $.is-verified;
has $.email;
has $.locale;

method guilds returns Promise {
    start {
        unless @!guilds {
            my $e = endpoint-for( self, 'get-guilds' ) ;
            my $p = await $.api.rest.get($e);
            say await $p.body
        }
        @!guilds
    }
}

#| to-json might not be necessary
method to-json {}
method from-json ($json) {
    my %constructor = $json<id username discriminator email locale>:kv;

    %constructor<avatar-hash is-bot is-mfa-enabled is-verified>
        = $json<avatar bot mfa_enabled verified>;

    %constructor<api> = $json<_api>;
    return self.new(|%constructor);
}
