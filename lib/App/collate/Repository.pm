package App::collate::Repository;

use strict;
use warnings;

use App::collate;

use Any::Moose;

has _assets => qw/ is ro lazy_build 1 /;
sub _build__assets {
    return {};
}

sub declare {
    my $self = shift;
    my $name = shift;
    my %assets = @_;

    return $self->assets( $name => App::collate->assets( %assets ) );
}

sub assets {
    my $self = shift;
    my $name = shift;

    if ( @_ ) {
        my $assets = shift;
        die unless defined $assets && ref $assets eq 'App::collate::Assets';
        return ( $self->_assets->{ $name } = $assets );
    }
    else {
        return $self->_assets->{ $name } or die;
    }
}

sub rename {
    my $self = shift;
    my ( $from, $to ) = @_;

    my $assets = $self->assets( $from );
    delete $self->_assets->{ $from };
    $self->assets( $to => $assets );
}

no Any::Moose;

sub has {
    my $self = shift;
    my $name = shift;

    return defined $self->_assets->{ $name };
}

1;
