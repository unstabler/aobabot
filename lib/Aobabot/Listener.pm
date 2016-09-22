package Aobabot::Listener;
use 5.010;
use utf8;
use strict;
use warnings;

use Module::Load;
use Moose;
use namespace::autoclean;

has 'context' => (
    is  => 'rw',
    isa => 'Aobabot',
    required => 1
);

has 'is_connected' => (
    is  => 'rw',
    isa => 'Bool',
    default => 0
);

has 'retry_count' => (
    is  => 'rw',
    isa => 'Int',
    default => 0
);

has 'tx' => (
    is  => 'rw',
);

has 'self_id' => (
    is  => 'rw',
    isa => 'Str'
);

has '_plugins' => (
    is  => 'ro',
    isa => 'HashRef',
    default => sub { {} }
);


sub CODE_FINISH_UNEXPECTED () { 1006 }

sub api {
    my $self = shift;
    return $self->context->api;
}

sub log {
    my $self    = shift;
    my $message = shift;
    $self->context->post('aobalog', $message);
}

sub start {
    my $self  = shift;
    my $quiet = shift || 0;

    if ($self->is_connected) {
        warn "Already Connected to Stream";
        return;
    }

    $self->is_connected(1);

    $self->api->call('rtm.start', {}, sub {
        my $response = shift;
        my $url = $response->{url};
        $self->self_id($response->{self}->{id});

        $self->create_tx($url);
    }, sub {
        warn "cannot call rtm.start";    
    });
}

sub create_tx {
    my $self = shift;
    my $url  = shift;

    warn "Connecting to $url..";
    my $tx = $self->api->ua->websocket($url, {
        'Sec-Websocket-Extensions' => 'permessage-deflate'    
    }, sub {
        my ($ua, $tx) = @_;

        if (defined $tx->is_websocket) {
            # 타임아웃 조정
            Mojo::IOLoop->stream(
                $tx->connection
            )->timeout(1800);
            $self->log("스트림에 연결하였습니다 @ " . (time));
            $tx->on('finish', sub {
                my ($tx, $code, $reason) = @_;
                $self->is_connected(0);
                $self->on_finish($code, $reason);
            });

            $tx->on('json', sub {
                my ($tx, $json) = @_;
                $self->on_message($json); 
            });
            
        } else {
            $self->log("스트림에 연결할 수 없었습니다");
            $self->is_connected(0);
        }
    });

    $self->tx($tx);
}

sub on_finish {
    my $self = shift;
    my ($code, $reason) = @_;

    # TODO: 재접속
    if ($code == CODE_FINISH_UNEXPECTED) {
        $self->start;
    }
}

sub on_message {
    my $self = shift;
    my $json = shift;

    say "Message Received: " . $json->{type};

    return if defined $json->{user} &&
              $json->{user} eq $self->self_id;

    for my $package (keys %{$self->_plugins}) {
        my $plugin = $self->_plugins->{$package};
        $plugin->on_message($json);
    }
}

sub register_plugin {
    my $self    = shift;
    my $package = shift;

    eval {
        load $package;

        my $plugin = $package->new(
            context => $self->context
        );

        $self->_plugins->{$package} = $plugin;
    };

    unless ($@) {
        $self->log("플러그인 `$package` 로드하였습니다");
    } else {
        $self->log("플러그인 `$package` 로드 실패하였습니다. ```$@```"); 
    }
}

__PACKAGE__->meta->make_immutable;

1;
