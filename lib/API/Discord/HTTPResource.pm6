unit package API::Discord;

=begin pod

=head1 NAME

API::Discord::JSONy - Role for objects that can be serialised to JSON

API::Discord::RESTy - Role for objects that can be sent/received over REST

API::Discord::HTTPResource - Role for objects that can be CRUD'd

=head1 DESCRIPTION

This file defines the three roles listed above. They are all related to one
another but not necessarily all required at once.

=head1 API::Discord::JSONy

This role defines the methods C<from-json> and C<to-json> that must be
implemented by the consuming class. Anything using this role can be sent to or
produced by RESTy.

=end pod


role JSONy is export {
    #| Builds the object from a hash. The hash is made from the JSON, courtesy
    #| of Cro.
    method from-json ($json) returns ::?CLASS { ... }
    #| Turns the object into a hash. from-json(to-json($object)) should return
    #| the same object (or at least an equivalent copy).
    method to-json returns Hash { ... }
}

=begin pod

=head1 API::Discord::RESTy[$base-url]

This role defines C<send> and C<fetch> and is parameterised with a base URL. It
is used to send or retrieve JSONy stuff.

This is intended to be applied to some sort of HTTP client - it expects C<self>
to have at least C<get> and C<post> methods that work the same as
L<Cro::HTTP::Client> because that's what we use.

=end pod

role RESTy[$base-url] is export {
    has $.base-url = $base-url;

    #| Sends a JSONy object to the given endpoint.
    method send(Str $endpoint, JSONy:D $object) {
        # TODO: does anything generate data such that we need to re-fetch after
        # creation?
        say "Send {$object.to-json} to $.base-url$endpoint";

        # TODO: Shall we be smart and decide whether it's a POST or PUT based on
        # the existence of an ID? If so, where? Discord::Object?
        self.post: "$.base-url$endpoint", body => $object.to-json;
    }

    #| Creates a JSONy object, given a full URL and the class.
    method fetch(Str $endpoint, JSONy:U $class) returns JSONy {
        # FIXME: surely this is a promise?
        my $json = self.get($endpoint);
        $class.from-json($json);
    }
}

=begin pod

=head1 API::Discord::HTTPResource

Represents an object that can be discovered via some HTTP mechanism. The
consuming class is expected to have a hash called C<%.ENDPOINTS>, the purpose of
which is to provide a set of URL path templates that can be filled in by the
object being dealt with.

Endpoint handling is not yet fully implemented.

A gap in this process is that it does mean that in order to fetch an existing
object by ID, it is necessary to create an empty object containing that ID, and
then replace it with the response from C<read>, which will be a new object,
fully-populated.

Since all of the methods communicate via a RESTy object, it is currently
necessary that the class consuming HTTPResource also consumes JSONy.

=end pod

role HTTPResource is export {
    #| Upload self, given a RESTy client. Returns a Promise that resolves to
    #| self.
    method create(RESTy $rest) {
        # FIXME: We will have to ask self for the formatted create endpoint
        # But maybe we should make endpoints easier to deal with first
        my $endpoint = %.ENDPOINTS<create>.format(self);
        $rest.send($endpoint, self).then({ self if $^a.result });
    }

    #| Given a self with an ID in it, goes and fetches the rest of it. Currently
    #| returns a copy of self with all the new data; too lazy to change this
    #| right now.
    method read(RESTy $rest) {
        my $endpoint = %.ENDPOINTS<read>.format(self);
        $rest.fetch($endpoint, ::?CLASS);
    }

    #method update;
    #method delete;
}
