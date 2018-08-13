unit package API::Discord;

role JSONy is export {
    # No need for from-json(Str) because Cro does that for us.
    method from-json ($json) returns ::?CLASS { ... }
    method to-json returns Hash { ... }
}

role RESTy[$base-url] is export {
    has $.base-url = $base-url;

    method send(Str $endpoint, JSONy:D $object) {
        say "Send {$object.to-json} to $.base-url$endpoint";

        self.post: "$.base-url$endpoint", body => $object.to-json;
    }

    method fetch(Str $endpoint, JSONy:U $class) returns JSONy {
        my $json = self.get($endpoint);
        $class.from-json($json);
    }
}

role HTTPResource does JSONy is export {
    method create(RESTy $rest) {
        # FIXME: We will have to ask self for the formatted create endpoint
        # But maybe we should make endpoints easier to deal with first
        my $endpoint = %.ENDPOINTS<create>.format(self);
        $rest.send($endpoint, self).then({ self if $^a.result });
    }
    method read(RESTy $rest) {
        my $endpoint = %.ENDPOINTS<read>.format(self);
        $rest.fetch($endpoint, ::?CLASS);
    }

    #method update;
    #method delete;
}
