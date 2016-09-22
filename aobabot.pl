#!/usr/bin/env perl
use utf8;
use strict;
use warnings;

use lib 'lib';
use JSON;
use Aobabot;
use Module::Load;

sub load_config {
    my $filename = shift || "config.json";
    my $json_raw;

    open my $fh, '<', $filename or die "Cannot open $filename X(";
    $json_raw .= $_ while <$fh>;
    close $fh;

    return decode_json($json_raw);
}


my $config = load_config();
my $aobachan = Aobabot->new(
    token => $config->{slack_token}
);

for my $plugin (@{$config->{plugins}}) {
    eval {
        $aobachan->listener->register_plugin($plugin);
    } or warn;
}

$aobachan->listener->start;

Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
