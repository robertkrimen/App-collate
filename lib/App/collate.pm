package App::collate;

use strict;
use warnings;

use App::collate::Assets;
use String::Util qw/ trim /;

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

    $assets->include( $options{ include } );
    $assets->attach( $options{ attach } );

    return $assets;
}

1;
