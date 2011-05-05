package App::collate;
# ABSTRACT: Collate .js and .css assets

use strict;
use warnings;

use String::Util qw/ trim /;


require App::collate::Assets;

sub _each ($$) {
    my $source = shift;
    my $iterator = shift;

    return unless defined $source;

    for my $line ( split m/\n/, $source ) {
        $line = trim $line;
        $iterator->( $line );
    }
}

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
