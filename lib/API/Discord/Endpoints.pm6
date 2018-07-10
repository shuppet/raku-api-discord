unit module API::Discord::Endpoints;

class X::API::Discord::Endpoint::NotEnoughArguments is Exception {
    has @.required is required;
    has $.endpoint is required;
    method message {
        return "You need to define {@.required} for endpoint {$.endpoint}";
    }
}

our %ENDPOINT =
    message => %(
        post => '/channels/{channel-id}/messages',
        get  => '/channels/{channel-id}/messages/{message-id}',
    )
;

sub endpoint-for ($resource, $method, *%args) is export {
    my $e = %ENDPOINT{$resource}{$method};
    my @required-fields = $e ~~ / '{' <( .+? )> '}' /;

    say %args, @required-fields, %args{@required-fields};

    unless %args{@required-fields}:exists.all {
        X::API::Discord::Endpoint::NotEnoughArguments.new(
            required => @required-fields,
            endpoint => "{$method.uc} $resource"
        ).throw;
    }

    return S:g['{' ( .+? ) '}' ] = %args{$/[0]} given $e;
}
