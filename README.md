![logo](https://user-images.githubusercontent.com/12242877/44151690-34cd913c-a09b-11e8-80b6-25e2f232193b.png)

`API::Discord` is a Perl6 module for interacting with the Discord API. Built on
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
git clone https://github.com/shuppet/p6-api-discord
cd p6-api-discord/ && zef install ${PWD}
```

## Usage

Full documentation can be found by reading the [wiki](https://github.com/shuppet/p6-api-discord/wiki) attached to this repository, or by reading the pod directly from the module source.

```
p6doc API::Discord
```

## Example

`API::Discord` is designed to do all the hard work for you. Let us handle the connection, authentication, heartbeats, message parsing and all that other boring stuff - leaving you to focus on writing logic for your applications.

```perl6
#!perl6

use API::Discord;

sub MAIN($token) {
    my $discord = API::Discord.new(:$token);

    await $discord.connect;

    react {
        whenever $discord.messages -> $message {
            (await $message.channel).send-message(
                $message.content
            );
        }
    }
}
```

## Acknowledgements

- [Jonathan 'jnthn' Worthington](https://github.com/jnthn) - answered many of our inane questions in the #perl6 Freenode IRC
- [Timo 'timotimo' Paulssen](https://github.com/timo) - also answered a great deal of technical questions when jnthn wasn't fast enough :P
- [Tomislav 'Novica' Novački](https://www.instagram.com/novackinet) - provided our lovely graphics for `API::Discord` and other projects
