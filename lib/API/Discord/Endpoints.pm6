# Not sure we're using this, and if we are, not properly.

class X::API::Discord::Endpoint::NotEnoughArguments is Exception {
    has @.required is required;
    has $.endpoint is required;
    method message {
        return "You need to define {@.required} for endpoint {$.endpoint}";
    }
}

module API::Discord::Endpoints {

    our %ENDPOINTS =
        User =>
        {
            read => '/users/{id}',
            update => '/users/{id}',

            get-guilds => '/users/{id}/guilds',
            leave-guild => '/users/{id}/guilds',

            get-dms => '/users/{id}/channels',
            create-dm => '/users/{id}/channels',

            # This is OAuth2 stuff, so we probably won't use it
            get-connections => '/users/{id}/connections'
        },
        Channel =>
        {
            create => '/channels',
            read => '/channels/{id}',
            update => '/channels/{id}',
            delete => '/channels/{id}',

            get-messages => '/channels/{id}/messages',
            bulk-delete-messages => '/channels/{id}/messages/bulk-delete',

            edit-permissions => '/channels/{id}/permissions/{overwrite-id}',
            delete-permission => '/channels/{id}/permissions/{overwrite-id}',

            get-invites => '/channels/{id}/invites',
            create-invite => '/channels/{id}/invites',

            trigger-typing => '/channels/{id}/typing',

            pinned-messages => '/channels/{id}/pins',
            pinned-message => '/channels/{id}/pins/{message-id}',

            add-group-recipient => '/channels/{id}/recipients/{user.id}',
            remove-group-recipient => '/channels/{id}/recipients/{user.id}',
        },
        Guild =>
        {
            create => '/guilds',
            read => '/guilds/{id}',
            update => '/guilds/{id}',
            delete => '/guilds/{id}',

            get-channels => '/guilds/{id}/channels',
            create-channel => '/guilds/{id}/channels',

            get-member => '/guilds/{id}/members/{user-id}',
            list-members => '/guilds/{id}/members',
            add-member => '/guilds/{id}/members/{user-id}',
            modify-member => '/guilds/{id}/members/{user-id}',
            remove-member => '/guilds/{id}/members/{user-id}',

            get-bans => '/guilds/{id}/bans',
            create-ban => '/guilds/{id}/bans/{user.id}',
            revoke-ban => '/guilds/{id}/bans/{user.id}',

            get-prune-count => '/guilds/{id}/prune',
            begin-prune => '/guilds/{id}/prune',

            get-integrations => '/guilds/{id}/integrations',
            create-integration => '/guilds/{id}/integrations',
            modify-integration => '/guilds/{id}/integrations/{integration-id}',
            delete-integration => '/guilds/{id}/integrations/{integration-id}',
            sync-integration => '/guilds/{id}/integrations/{integration-id}/sync',

            get-embed => '/guilds/{id}/embed',
            modify-embed => '/guilds/{id}/embed',

            modify-nick => '/guilds/{id}/members/@me/nick',
            get-invites => '/guilds/{id}/invites',
            get-voice-regions => '/guilds/{id}/regions',
            audit-log => '/guilds/{id}/audit-logs',
            vanity-url => '/guilds/{id}/vanity-url',
        },
        Message =>
        {
            create => '/channels/{channel-id}/messages',
            read => '/channels/{channel-id}/messages/{id}',
            update => '/channels/{channel-id}/messages/{id}',
            delete => '/channels/{channel-id}/messages/{id}',
        },
        Reaction =>
        {
            create => '/channels/{message.channel-id}/messages/{message.id}/reactions/{emoji}/{user}',
            read => '/channels/{message.channel-id}/messages/{message.id}/reactions/{emoji}',
            delete => '/channels/{message.channel-id}/messages/{message.id}/reactions/{emoji}/{user}',
        }
    ;

    sub endpoint-for ($r, $method, *%args) is export {
        my $type = $r.WHAT.^name.split('::')[*-1];

        my $e = %ENDPOINTS{$type}{$method};
        my @required-fields = $e ~~ m:g/ '{' <( .+? )> '}' /;

        for @required-fields -> $f {
            next if %args{$f};

            my @f = $f.split('.');

            my $val = reduce { $^a."$^b"() }, $r, |@f;
            %args{$f} = $val if $val;
        }

        unless %args{@required-fields}:exists.all {
            X::API::Discord::Endpoint::NotEnoughArguments.new(
                required => @required-fields,
                endpoint => "{$method.uc} $type"
            ).throw;
        }

        return S:g['{' ( .+? ) '}' ] = %args{$/[0]} given $e;
    }
}
