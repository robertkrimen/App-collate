package App::assetize;

use strict;
use warnings;

use App::assetize::Assets;
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

    my $assets = App::assetize::Assets->new( base => $options{ base } );

    _each( $options{ manifest }, sub {
        my $asset = shift;
        $assets->manifest->add( $asset );
    } );

    _each( $options{ attach }, sub {
        my $asset = shift;
        $assets->attach_manifest->add( $asset );
    } );

    return $assets;
}

1;
