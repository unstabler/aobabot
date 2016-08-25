package Aobabot::Plugin;
use strict;
use warnings;

use Moose::Role;
use Cwd;

has 'context' => (
    is  => 'rw',
    isa => 'Aobabot',
    required => 1
);

requires 'on_message';

sub log {
    my $self    = shift;
    my $message = shift;
    $self->context->post(
        'aobalog', 
        sprintf("*%s*: %s", ref $self, $message)
    );
}

sub private_path {
    my $self = shift;
    my $package = (ref $self) =~ s/::/-/gr;
    my $path = getcwd . '/private/' . $package;

    return $path;
}
1;
