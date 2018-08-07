unit module API::Discord;

role RESTy is export {
    has $.base-url;
    method send(Str $endpoint, %json) {
        say "Send {%json.gist} to $.base-url$endpoint";

        self.post: "$.base-url$endpoint", body => %json;
    }
}

role JSONy is export {
    # No need for from-json(Str) because Cro does that for us.
    method from-json (%json) returns ::?CLASS { ... }
    method to-json returns Hash { ... }
}

role HTTPResource does JSONy is export {
    method create(RESTy $rest) {
        # FIXME: We will have to ask self for the formatted create endpoint
        # But maybe we should make endpoints easier to deal with first
        my $endpoint = %.ENDPOINTS<create>.format(:$.channel-id);
        my $data = self.to-json;
        $rest.send($endpoint, $data).then({ self if $^a.result });
    }
    #method read;
    #method update;
    #method delete;
}
