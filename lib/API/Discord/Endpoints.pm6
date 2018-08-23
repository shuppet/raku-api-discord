# Not sure we're using this, and if we are, not properly.
unit module API::Discord::Endpoints;
class API::Discord::HTTPResource { ... }

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
    ),

;

sub endpoint-for ($resource, $method, *%args) is export {
    my $e = %ENDPOINT{$resource}{$method};
    my @required-fields = $e ~~ m:g/ '{' <( .+? )> '}' /;

    unless %args{@required-fields}:exists.all {
        X::API::Discord::Endpoint::NotEnoughArguments.new(
            required => @required-fields,
            endpoint => "{$method.uc} $resource"
        ).throw;
    }

    return S:g['{' ( .+? ) '}' ] = %args{$/[0]} given $e;
}

multi method format(Str:D: API::Discord::HTTPResource $r) returns Str {
    # get format data from object
}
