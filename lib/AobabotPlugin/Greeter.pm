package AobabotPlugin::Greeter;
use utf8;
use strict;
use warnings;

use Moose;
use Aobabot::Plugin;
use JSON;
use Encode qw/decode/;

with 'Aobabot::Plugin';

has 'patterns' => (
    is  => 'rw',
    isa => 'HashRef',
    
    builder => 'load_patterns'
);

sub load_patterns {
    my $self = shift;
    my $path = $self->private_path;

    my $content;
    open my $fh, '<', $path . '/config.json' or return {};
    $content .= $_ while <$fh>;
    close $fh;

    my $json = decode_json($content);
    return $json->{patterns};
}

sub on_message {
    my $self = shift;
    my $json = shift;

    if ($json->{type} eq 'message') {
        my $text = $json->{text};
        my $user = $json->{user};

        return unless defined $text;

        my %patterns = %{ $self->patterns };
        while (my ($pattern, $content) = each %patterns) {
            if ($text =~ qr/$pattern/) {

                if (ref $content eq 'HASH') {
                    $self->context->post(
                        $json->{channel},
                        '',
                        {
                            'attachments' => decode('utf-8', encode_json([$content]))
                        }
                    )
                } else {
                    $self->context->post(
                        $json->{channel}, 
                        sprintf('<@%s> %s', $json->{user}, $content)
                    );
                }

                last;
            }
        }
    }
}

1;
