![logo](https://user-images.githubusercontent.com/12242877/44151690-34cd913c-a09b-11e8-80b6-25e2f232193b.png)

`API::Discord` is a Raku (formerly Perl 6) module for interacting with the Discord API. Built on
top of [`Cro::WebSocket::Client`](https://github.com/croservices/cro-websocket)
and [`Cro::HTTP::Client`](https://github.com/croservices/cro-http), this allows
for fast asynchronous operations between your application and the API.

## Installation

### ... from zef

```
zef install API::Discord
```

### ... from source

```
git clone https://github.com/shuppet/raku-api-discord
cd raku-api-discord/ && zef install ${PWD}
```

## Usage

Full documentation can be found by reading the pod6 directly from the module source.

```
p6doc API::Discord
```

## Example

`API::Discord` is designed to do all the hard work for you. Let us handle the connection, authentication, heartbeats, message parsing and all that other boring stuff - leaving you to focus on writing logic for your applications.

```raku
#!raku

use API::Discord;
use API::Discord::Debug; # remove to disable debug output

sub MAIN($token) {
    my $discord = API::Discord.new(:$token);

    $discord.connect;
    await $discord.ready;

    react {
        whenever $discord.messages -> $message {
            $message.channel.send-message($message.content);
        }
    }
}
```
More examples can be found within the [`examples/`](https://github.com/shuppet/raku-api-discord/tree/master/examples) directory of this repository.

## Support

### Official 

Join our official Discord server where we discuss development, bugs and test changes or new features to our library. Please note that this is a volunteer project and we all have real lives, day jobs and other responsiblities outside of the Internet. Replies may not be immediate and a resolution of your problem is not guaranteed outside of valid bug reports (for which raising an [issue](https://github.com/shuppet/raku-api-discord/issues/new) here on GitHub is far preferable).

[![image](https://discordapp.com/api/guilds/502109774901542924/embed.png?style=banner2)](https://discord.gg/8FqQFCF)

### Community

If you have a more general Raku question, or need help with a programming issue then it might be best to join the Raku Discord community instead. Some of the members there are also familiar with `API::Discord` and it's quite likely they'll be able to help you faster than we can. They're also really nice people. :)

[![image](https://discordapp.com/api/guilds/538407879980482560/embed.png?style=banner2)](https://discord.gg/VzYpdQ6)
