#!perl6

use API::Discord;

my $c = await API::Discord.new.connect;

say $c.gist;
