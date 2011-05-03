package App::assetize::Assets::Manifest;

use strict;
use warnings;

use Try::Tiny;
use String::Util qw/ trim /;

use Any::Moose;

has _manifest => qw/ is ro lazy_build 1 /;
sub _build__manifest {
    return [];
}

sub _normalize {
    my $self = shift;
    my $value = shift;
    return unless defined $value;
    $value = trim $value;
    return unless length $value;
    return $value;
}

sub add {
    my $self = shift;
    push @{ $self->_manifest }, map { $self->_normalize( $_ ) } @_;
}

sub all {
    my $self = shift;
    return @{ $self->_manifest };
}

#sub _itemize {
#    my $self = shift;
#    my $path = shift;
#    return App::assetize::Assets::Manifest::Item->new( path => $path );
#}

#package App::assetize::Assets::Manifest::Item;

#use Any::Moose;

#has path => qw/ is rw required 1 /;

1;
