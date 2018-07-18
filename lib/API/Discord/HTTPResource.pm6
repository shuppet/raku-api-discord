unit module API::Discord;

role JSONy is export {
    # No need for from-json(Str) because Cro does that for us.
    method from-json (%json) returns ::?CLASS { ... }
    method to-json returns Hash { ... }
}

role HTTPResource is JSONy is export {

    method create(API::Discord::Connection::REST $rest) {
        my $endpoint = %.ENDPOINTS<create>.format(:$.channel-id);
        my $data = self.to-json;
        $rest.send($endpoint, $data).then({ self if $^a.result });
    }
    #method read;
    #method update;
    #method delete;
}
