use Cro::HTTP::BodySerializers;
use API::Discord::HTTPResource;

class API::Discord::Comms::BodySerialiser is Cro::HTTP::BodySerializer::JSON {
    method is-applicable(Cro::HTTP::Message $message, $body --> Bool) {
        return $body ~~ API::Discord::HTTPResource::JSONy;
    }

    method serialize(Cro::HTTP::Message $message, $body --> Supply) {
        my $actual-body = $body.to-json;
        nextwith $actual-body;
    }
}
