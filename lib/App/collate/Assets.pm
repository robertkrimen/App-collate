package App::collate::Assets;

use strict;
use warnings;

use Try::Tiny;
use App::collate::Assets::Manifest;
use Path::Class;

use Any::Moose;

has base => qw/ is ro required 1 isa Str /;

has manifest => qw/ is ro lazy 1 /, default => sub {
    return App::collate::Assets::Manifest->new;
};

has import_manifest => qw/ is ro lazy 1 /, default => sub {
    return App::collate::Assets::ImportManifest->new;
};

has attach_manifest => qw/ is ro lazy 1 /, default => sub {
    return App::collate::Assets::AttachManifest->new;
};

sub include {
    my $self = shift;
    my $include = shift;

    App::collate::_each( $include, sub {
        my $asset = shift;
        $self->manifest->add( $asset );
    } );
}

sub attach {
    my $self = shift;
    my $attach = shift;

    App::collate::_each( $attach, sub {
        my $asset = shift;
        $self->attach_manifest->add( $asset );
    } );
}

sub import {
    my $self = shift;
    return unless ref $self;
    my $import = shift;
    App::collate::_each( $import, sub {
        my $asset = shift;
        $self->import_manifest->add( $asset );
    } );
}

sub write_manifest {
    my $self = shift;
    my %options =  @_;

    my $base = dir $self->base;

    my $into = $options{ into };
    die "*** Missing into" unless defined $into && length $into;
    $into = dir $into;

    my $repository = $options{ repository };

    die "*** Invalid into ($into): Not a directory or does not exist" unless -d $into;
    die "*** Invalid base ($base): Not a directory or does not exist" unless -d $base;

    my $manifest = App::collate::Assets::WriteManifest->new( base => $base, into => $into );

    $self->_populate_write_manifest( $manifest, $repository );

    return $manifest;
}

sub _populate_write_manifest {
    my $self = shift;
    my $manifest = shift;
    my $repository = shift;

    for my $assets ( $self->import_manifest->all ) {
        if ( ref $assets eq '' ) {
            if ( ! $repository ) {
                die "*** Missing repository to lookup assets ($assets)";
            }
            if ( ! $repository->has( $assets ) ) {
                die "*** Missing assets ($assets) in repository";
            }
            $assets = $repository->assets( $assets );
        }
        $assets->_populate_write_manifest( $manifest, $repository );
    }

    $manifest->add_asset( Path::Class::dir( $self->base )->file( $_ ), $_ ) for $self->manifest->all;

    {
        my @manifest = $self->attach_manifest->all;
        for my $item ( @manifest ) {
            my $source = Path::Class::dir( $self->base )->file( $item->path );
            if ( -d $source ) {
                my $base_source = dir $source;
                $base_source->recurse( callback => sub {
                    my $source = shift;
                    if ( -f $source && $source !~ m/\.(?:css|js)/ ) {
                        my $path = file( $item->path, substr "$source", length $base_source );
                        $manifest->add_attachment( $source, "$path" );
                    }
                } );
            }
            else {
                $manifest->add_attachment( $source, $item->path );
            }
        }
    }

}

1;
