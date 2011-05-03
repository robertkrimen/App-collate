package App::assetize::Assets;

use strict;
use warnings;

use Try::Tiny;
use App::assetize::Assets::Manifest;
use Path::Class;

use Any::Moose;

has base => qw/ is ro required 1 isa Str /;

has [qw/ manifest require_manifest /] => qw/ is ro lazy 1 /, default => sub {
    return App::assetize::Assets::Manifest->new;
};

has attach_manifest => qw/ is ro lazy 1 /, default => sub {
    return App::assetize::Assets::AttachManifest->new;
};

sub write_manifest {
    my $self = shift;
    my %options =  @_;

    my $base = dir $self->base;

    my $into = $options{ into };
    die "*** Missing into" unless defined $into && length $into;
    $into = dir $into;

    die "*** Invalid into (not a directory or does not exist)" unless -d $into;
    die "*** Invalid base (not a directory or does not exist)" unless -d $base;

    my $manifest = App::assetize::Assets::WriteManifest->new( base => $base, into => $into );

    $manifest->add_asset( $_ ) for $self->manifest->all;

    {
        my @manifest = $self->attach_manifest->all;
        for my $item ( @manifest ) {
            my $source = $base->file( $item->path );
            if ( -d $source ) {
                my $base_source = dir $source;
                $base_source->recurse( callback => sub {
                    my $source = shift;
                    if ( -f $source && $source !~ m/\.(?:css|js)/ ) {
                        my $path = file( $item->path, substr "$source", length $base_source );
                        $manifest->add_attachment( "$path" );
                    }
                } );
            }
            else {
                $manifest->add_attachment( $item->path );
            }
        }
    }

    return $manifest;
}

1;
