package AobabotPlugin::Aobasama;
use utf8;
use strict;
use warnings;

use feature 'say';

use Moose;
use Aobabot::Plugin;

with 'Aobabot::Plugin';

sub ANSWERS () { ['응.', '그럴까.', '그러지 뭐.', '그래.', '아니.', '절대 안돼.', '나도 몰라.', '안돼.', '좋아', '싫어', '마음대로 해.', '그렇게 해.', '하지 마.'] }

sub BUILD {
    my $self = shift;
    srand time;
}

sub on_message {
    my $self = shift;
    my $json = shift;

    if ($json->{type} eq 'message') {
        my $text = $json->{text};
        my $user = $json->{user};

        return unless defined $text;

        if ($text =~ m/^아오바\s?님.+?[요죠]/) {
            my $answer = ANSWERS->[int rand scalar @{(ANSWERS)}];
            $self->context->post(
                $json->{channel}, 
                sprintf("<@%s> *아오바 님* 의 대답은...\n> *%s*", $json->{user}, $answer),
                {
                    as_user  => \0,
                    username => "아오바 님"
                }
            );
   
        }
    }
}

1;
