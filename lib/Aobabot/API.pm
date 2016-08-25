package Aobabot::API;
use 5.010;
use utf8;
use strict;
use warnings;

use Moose;
use namespace::autoclean;
use Mojo::UserAgent;

has 'token' => (
    is  => 'rw',
    isa => 'Str',
    required => 1
);

has 'ua' => (
    is  => 'rw',
    isa => 'Mojo::UserAgent',
    builder => '_build_ua'
);

sub _build_ua {
    my $self = shift;
    return Mojo::UserAgent->new();
}

sub get_url {
    my $self   = shift;
    my $method = shift;

    return 'https://slack.com/api/'.$method;
}

sub call {
    my $self = shift;
    my ($method, $args, $cb_success, $cb_failure) = @_;

    my $url = $self->get_url($method);
    my $tx  = $self->ua->post(
        $url,
        form => {
            token => $self->token,
            %{ $args }
        },
        sub {
            my ($ua, $tx) = @_;
            my $code = $tx->res->code;
            my $json = $tx->res->json;

            if (defined $json && $json->{ok}) {
                $cb_success->($json) if ref $cb_failure eq 'CODE';   
            } else {
                my $reason = defined $json ? $json->{error} : 
                                             "HTTP $code";
                warn "call $method failed: $reason";
                $cb_failure->($tx) if ref $cb_failure eq 'CODE';
            }
        }
    );
}

__PACKAGE__->meta->make_immutable;
1;
