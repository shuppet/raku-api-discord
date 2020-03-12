use API::Discord::HTTPResource;

role API::Discord::DataObject does HTTPResource does JSONy { }

=begin pod

=head1 API::Discord::Object

=end pod

role API::Discord::Object {
    has $.id;
    has $.api is required;
    # I don't know how to define this yet
    # has $.real = ...;

    method create {
        start {
            my $r = $.real.create($.api.rest).result.body.result;
            $!id = $r<id>;
            self;
        }
    }

    method update {
        start {
            await $.real.update($.api.rest);
            self;
        }
    }

    method delete {
        start {
            await $.real.delete($.api.rest);
            self;
        }
    }
}


=begin pod

=head1 NAME

API::Discord::Object - Base class for all the Discord things

=head1 DESCRIPTION

Object is a thin class that only contains the information required to populate
its C<$.real> object on demand. For most objects this is C<$.id>; some will have
additional data, like how Message also has channel ID. All consumers of this
role will be responsible for constructing their own C<$.real> on demand.

The key part here is that C<$.id> is the I<only> part that is not required,
because a new object will not have an ID yet. Any other data (like channel ID)
is required.

The C<$.real> property must also do C<API::Discord::DataObject>.

As a result, we can now handle the CRUD methods, proxy them to $.real, and
populate the ID field from the response, where necessary.

We then facade them so that their Promise now resolves to this outer Object and
not the DataObject inside it.

We don't need "read" on these objects, as that is done simply by accessing any
of the properties of the C<$.real> object.

=head1 API::Discord::DataObject

This Role simply merges  L<JSONy|API::Discord::JSONy> and
L<HTTPResource|API::Discord::HTTPResource>. It is marshalled via
L<API::Discord::Object>s.

The purpose of this role is to be applied to classes whose structures mimic the
actual JSON data returned from Discord's API. As a result they all have
C<from-json> and C<to-json>.

=end pod
