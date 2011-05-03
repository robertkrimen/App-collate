package App::collate::Assets::ManifestRole;

use strict;
use warnings;

use Try::Tiny;
use String::Util qw/ trim /;

use Any::Moose 'Role';

has _manifest => qw/ is ro lazy_build 1 /;
sub _build__manifest {
    return [];
}

sub _normalize {
    my $self = shift;
    my $value = shift;
    return unless defined $value;
    if ( ref $value eq '' ) {
        $value = trim $value;
        return unless length $value;
    }
    return $value;
}

sub parse {
    my $self = shift;
    my $value = shift;
    return $value;
}

sub add {
    my $self = shift;
    push @{ $self->_manifest }, map { $self->parse( $_ ) } map { $self->_normalize( $_ ) } @_;
}

sub all {
    my $self = shift;
    return @{ $self->_manifest };
}

package App::collate::Assets::Manifest;

use strict;
use warnings;

use Any::Moose;

with 'App::collate::Assets::ManifestRole';

package App::collate::Assets::AttachManifest;

use strict;
use warnings;

use Any::Moose;

with 'App::collate::Assets::ManifestRole';

sub parse {
    my $self = shift;
    my $value = shift;
    my $shift_prefix = '';
    if ( $value =~ m/^(.+)\s+\=\>\s+(.+)$/ ) {
        $value = $1;
        $shift_prefix = $2;
    }
    return App::collate::Assets::AttachManifest::Item->new( path => $value, shift_prefix => $shift_prefix );
};

package App::collate::Assets::AttachManifest::Item;

use strict;
use warnings;

use Any::Moose;

has [qw/ path shift_prefix /] => qw/ is ro required 1 isa Str /;

package App::collate::Assets::WriteManifest;

use strict;
use warnings;

use Path::Class;

use Any::Moose;

with 'App::collate::Assets::ManifestRole';

has [qw/ base into /] => qw/ is ro required 1 isa Path::Class::Dir /;

sub add_asset {
    my $self = shift;
    my $path = shift;

    $self->add({ path => $path });
}

sub add_attachment {
    my $self = shift;
    my $path = shift;

    $self->add({ path => $path, attachment => 1 });
}

sub parse {
    my $self = shift;
    my $value = shift;

    my $path = $value->{ path };
    my $source = $self->base->file( $path );
    my $target = $self->into->file( $path );

    die "*** Invalid asset \"$source\" (not a file or does not exist)" unless -f $source;

    my @item;
    push @item, path => $path, source => $source, target => $target;
    push @item, attachment => 1 if $value->{ attachment };

    return App::collate::Assets::WriteManifest::Item->new( @item );
}

package App::collate::Assets::WriteManifest::Item;

use strict;
use warnings;

use Any::Moose;

has path => qw/ is ro required 1 isa Str /;
has [qw/ source target /] => qw/ is ro required 1 isa Path::Class::File /;
has attachment => qw/ is ro /;

package App::collate::Assets::ImportManifest;

use strict;
use warnings;

use Any::Moose;

with 'App::collate::Assets::ManifestRole';

sub parse {
    my $self = shift;
    my $assets = shift;

    die "Invalid assets ($assets)" unless blessed $assets && $assets->isa( 'App::collate::Assets' );
    return $assets;
}

1;