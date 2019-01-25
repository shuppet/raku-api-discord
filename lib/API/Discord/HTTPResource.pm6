use API::Discord::Endpoints;

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

This role defines C<send>, C<fetch>, and C<remove>, and is parameterised with a
base URL. It abstracts over the top of an HTTP client, so requires C<get>,
C<post>, C<put>, and C<delete> methods.

It is intended to be applied to L<Cro::HTTP::Client>, so the aforementioned
methods should match those.

=end pod

role RESTy[$base-url] is export {
    has $.base-url = $base-url;

    multi method get ($uri, %args) {
        callwith("$.base-url$uri", %args);
    }
    multi method get ($uri, *%args) {
        callwith("$.base-url$uri", |%args);
    }
    multi method post ($uri, %args) {
        callwith("$.base-url$uri", %args);
    }
    multi method post ($uri, *%args) {
        callwith("$.base-url$uri", |%args);
    }
    multi method patch ($uri, %args) {
        callwith("$.base-url$uri", %args);
    }
    multi method patch ($uri, *%args) {
        callwith("$.base-url$uri", |%args);
    }
    multi method put ($uri, %args) {
        callwith("$.base-url$uri", %args);
    }
    multi method put ($uri, *%args) {
        callwith("$.base-url$uri", |%args);
    }
    multi method delete ($uri, %args) {
        callwith("$.base-url$uri", %args);
    }
    multi method delete ($uri, *%args) {
        callwith("$.base-url$uri", |%args);
    }

    #| Sends a JSONy object to the given endpoint. Updates if the object has an
    #| ID; creates if it does not.
    method send(Str $endpoint, JSONy:D $object) returns Promise {
        if $object.can('self-send') {
            return $object.self-send($endpoint, self)
        }
        # TODO: does anything generate data such that we need to re-fetch after
        # creation?
        if $object.can('id') and $object.id {
            self.put: $endpoint, body => $object.to-json;
        }
        else {
            self.post: $endpoint, body => $object.to-json;
        }
    }

    #| Sends a PUT but no data required. Useful to avoid creating whole classes
    #| just so they can self-send
    method touch(Str $endpoint) returns Promise {
        self.put: "$.base-url$endpoint", body => {};
    }

    #| Creates a JSONy object, given a full URL and the class.
    method fetch(Str $endpoint, JSONy:D $obj) returns Promise {
        start {
            my $b = await (await self.get($endpoint)).body;
            $obj.from-json($b);
        }
    }

    #| Deletes the thing with DELETE
    method remove(Str $endpoint) returns Promise {
        self.delete: "$.base-url$endpoint";
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
    #| self. Not all resources can be created.
    multi method create(RESTy $rest) {
        my $endpoint = endpoint-for(self, 'create');
        $rest.send($endpoint, self).then({ self if $^a.result });
    }

    #| Given a self with an ID in it, goes and fetches the rest of it. Returns a
    #| Promise. This will resolve to a copy of self; this may be fixed later to
    #| fill in self.
    multi method read(RESTy $rest) {
        my $endpoint = endpoint-for(self, 'read');
        start {
            await $rest.fetch($endpoint, self);
            self;
        }
    }

    #| Updates the resource. Must have an ID already. Returns a Promise for the
    #| operation.
    multi method update(RESTy $rest) {
        my $endpoint = endpoint-for(self, 'update');
        $rest.send($endpoint, self).then({ self if $^a.result });
    }

    #| Deletes the resource. Must have an ID already. Not all resources can be
    #| deleted. Returns a Promise.
    multi method delete(RESTy $rest) {
        my $endpoint = endpoint-for(self, 'delete');
        $rest.remove($endpoint, self).then({ self if $^a.result });
    }
}
