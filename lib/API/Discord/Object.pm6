use API::Discord::HTTPResource;

unit role API::Discord::Object does HTTPResource does JSONy;

=begin pod

=head1 NAME

API::Discord::Object - Base class for all the Discord things

=head1 DESCRIPTION

This base class is a  L<JSONy|API::Discord::JSONy>
L<Resource|API::Discord::HTTPResource>. It also defines a single attribute,
C<$.api>. Any object made through the API has the API in this attribute, This
allows objects to ask the API for other, related objects, since it is the API
that is connected to Discord in the first place.

=head1 COMMON FEATURES

=head2 JSON fields

JSON fields are those attributes of the Object that map directly to the JSON
fields in the Discord documentation.

Since we are not required to adhere to the structures in the documentation, some
changes are made. First, we replace underscores with dashes; and then we alter
the names of many boolean fields to have boolean-meaning names. This latter
change often simply involves the addition of C<is-> or C<has-> or something like
that.

In general, the meaning of one of the JSON fields should be clear from its name,
and if not, it should be clear which field in the Discord documentation it
refers to.

Exceptions may come in when the Discord JSON structure is dodgy; for example, if
they populate a field with an ID but the field is not named C<_id>, then we will
call it C<-id> because of the Object properties.

=head2 Object properties

Object properties are inflated objects. These usually correspond to C<-id> JSON
fields, but in some cases we have reverse-engineered a relationship that goes
the other way.

Sometimes Object properties and JSON fields coïncide. For example, Messages have
Embed objects, but no C<embed-ids>. That's because the JSON structure in the
Discord documentation has the embed objects in their entirety within the message
object, rather than provided by ID. In this case, the attribute is still
considered an Object property, because we can inflate an Embed object from JSON,
and deflate it to JSON, automatically. The point is that to the user, it is an
object, not a simple type.

=head1 PROPERTIES

=end pod

#| A handle on the API::Discord object that made this
has $.api;
