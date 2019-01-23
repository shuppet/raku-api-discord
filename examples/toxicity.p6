#!perl6

use API::Discord;
use Cro::HTTP::Client;

sub MAIN($discord-token, $perspective-token) {
    my $discord = API::Discord.new(:token($discord-token));

    await $discord.connect;
    my $http = Cro::HTTP::Client.new(
        content-type => 'application/json',
        http => '1.1'
    );

    react {
        whenever $discord.messages -> $message {

            say $message.content;

            my $toxicity = await $http.post(
                "https://commentanalyzer.googleapis.com/v1alpha1/comments:analyze?key={$perspective-token}",
                body => {
                    comment => {
                        text => $message.content
                    },
                    languages => ["en"],
                    requestedAttributes => { TOXICITY => {} }
                }
            );

            my $result = await $toxicity.body;

            say $result<attributeScores><TOXICITY>;

            if $result<attributeScores><TOXICITY><summaryScore><value> > 0.7 {
                $message.add-reaction('☹');
            }
        }
    }
}
