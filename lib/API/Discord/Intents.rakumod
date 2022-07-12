unit module API::Discord::Intents;

# This module mostly exists for the name - currently it doesn't do anything
# special. We might start to use it for anything that requires domain knowledge
# of how intents work

enum INTENT is export (
    guilds                  => 1 +< 0,
    guild-members           => 1 +< 1,
    guild-bans              => 1 +< 2,
    guild-emojis            => 1 +< 3,
    guild-integrations      => 1 +< 4,
    guild-webhooks          => 1 +< 5,
    guild-invites           => 1 +< 6,
    guild-voice-states      => 1 +< 7,
    guild-presences         => 1 +< 8,
    guild-messages          => 1 +< 9,
    guild-message-reactions => 1 +< 10,
    guild-message-typing    => 1 +< 11,
    direct-messages         => 1 +< 12,
    direct-message-reactions=> 1 +< 13,
    direct-message-typing   => 1 +< 14,
    message-content         => 1 +< 15,
    guild-scheduled-events  => 1 +< 16,
    auto-moderation-configuration => 1 +< 20,
    auto-moderation-execution     => 1 +< 21,
);
