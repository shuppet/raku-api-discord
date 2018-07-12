unit role API::Discord::HTTPMessage;

method create(API::Discord::Connection::REST $rest) {
    my $endpoint = %.ENDPOINTS<create>.format(:$.channel-id);
    my $data = self.to-json;
    $rest.send($endpoint, $data).then({ self if $^a.result });
}
#method read;
#method update;
#method delete;

method from-json {...};
method to-json {...};
