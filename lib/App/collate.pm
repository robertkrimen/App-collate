package App::collate;
# ABSTRACT: Collate .js and .css assets

use strict;
use warnings;

require App::collate::Assets;

sub assets {
    my $self = shift;
    my %options = @_;

    my $assets = App::collate::Assets->new( base => $options{ base } );

    $assets->import( $options{ import } );
    $assets->include( $options{ include } );
    $assets->attach( $options{ attach } );

    return $assets;
}

1;
