use Object::Delayed;
use API::Discord::Object;
use API::Discord::Endpoints;

unit class API::Discord::User does API::Discord::Object is export;

class ButReal does API::Discord::DataObject {
    has $.username;
    has $.discriminator;
    has $.avatar;        # The actual image
    has $.avatar-hash;   # The URL bit for the CDN
    has $.is-bot;
    has $.is-mfa-enabled;
    has $.is-verified;
    has $.email;
    has $.locale;

    # to-json might not be necessary
    method to-json {}
    method from-json ($json) {
        my %constructor = $json<id username discriminator email locale real-id>:kv;

        %constructor<avatar-hash is-bot is-mfa-enabled is-verified>
            = $json<avatar bot mfa_enabled verified>;

        %constructor<api> = $json<_api>;
        return self.new(|%constructor);
    }
}

has Promise $!dms-promise;
has Promise $!guilds-promise;

#| Use real-id if you want to compare the user's numeric ID. This lets us put
#| '@me' in id itself, for endpoints
has $.real-id;

has $.real handles <
    username
    discriminator
    avatar
    avatar-hash
    is-bot
    is-mfa-enabled
    is-verified
    email
    locale
> = slack { await API::Discord::User::ButReal.read({:$!id, :$!api}, $!api.rest) };

multi method reify (::?CLASS:U: $data, $api) {
    ButReal.new(|%$data, :$api);
}

multi method reify (::?CLASS:D: $data) {
    my $r = ButReal.new(|%$data, api => $.api);
    $!real = $r;
}

submethod TWEAK() {
    $!real-id //= $!id;
}

method guilds returns Promise {
    if not $!guilds-promise {
        $!guilds-promise = start {
            my @guilds;
            my $e = endpoint-for( self, 'get-guilds' ) ;
            my $p = await $.api.rest.get($e);
            @guilds = (await $p.body).map( { $!api.inflate-guild($_) } );
            @guilds;
        }
    }

    $!guilds-promise
}

method dms returns Promise {
    if not $!dms-promise {
        $!dms-promise = start {
            my @dms;
            my $e = endpoint-for( self, 'get-dms' ) ;
            my $p = await $.api.rest.get($e);
            @dms = (await $p.body).map: $!api.inflate-channel(*);
            @dms;
        }
    }

    $!dms-promise
}


method create-dm($user) returns Promise {
    start {
        my $body = { recipient_id => $user.id };
        my $ret = await $.api.post: endpoint-for(self, 'create-dm'), body => $body;
        my $dm = await $ret.body;
        $.api.inflate-channel($dm);
    }
}

=begin pod

=head1 NAME

API::Discord::User - Represents Discord user

=head1 DESCRIPTION

Represents a Discord user, usually sent to us via the websocket. See
L<https://discordapp.com/developers/docs/resources/user>.

Users cannot be created or deleted.

See also L<API::Discord::Object>.

=head1 PROMISES

=head2 guilds

Resolves to a list of L<API::Discord::Guild> objects

=head2 dms

Resolves to a list of L<API::Discord::Channel> objects (direct messages)

=head1 METHODS

=head2 create-dm

Creates a DM with the provided C<$user>. This is an L<API::Discord::Channel>
object; the method returns a Promise that resolves to this.

=end pod
