package Aobabot;
use 5.010;
use utf8;
use strict;
use warnings;

use Moose;
use namespace::autoclean;

use Aobabot::API;
use Aobabot::Listener;

has 'token' => (
    is  => 'rw',
    isa => 'Str',
    required => 1
);

has 'api' => (
    is  => 'ro',
    isa => 'Aobabot::API',

    lazy    => 1,
    builder => '_build_api'
);

has 'listener' => (
    is  => 'ro',
    isa => 'Aobabot::Listener',

    lazy    => 1,
    builder => '_build_listener'
);

sub _build_api {
    my $self = shift;
    return Aobabot::API->new(
        token => $self->token
    );
}

sub _build_listener {
    my $self = shift;
    return Aobabot::Listener->new(
        context => $self 
    );
}

sub post {
    my $self = shift;
    my ($channel, $message, $args) = @_;

    $self->api->call('chat.postMessage', {
        channel => $channel,
        text    => $message,
        as_user => \1,

        %{ $args || {} }
    });
}

__PACKAGE__->meta->make_immutable;

1;
