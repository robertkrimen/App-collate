package App::collate::Assets::ManifestRole;

use strict;
use warnings;

use Try::Tiny;
use String::Util qw/ trim /;
use App::collate;

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

use App::collate::Moose;

with 'App::collate::Assets::ManifestRole';

has_dir [qw/ into /] => qw/ is ro required 1 isa Path::Class::Dir /;

has _seen => qw/ is ro isa HashRef lazy_build 1 /;
sub _build__seen {
    return {};
}

sub add_asset {
    my $self = shift;
    my $source = shift;
    my $path = shift;

    $self->add({ source => $source, path => $path });
}

sub add_attachment {
    my $self = shift;
    my $source = shift;
    my $path = shift;

    $self->add({ source => $source, path => $path, attachment => 1 });
}

sub parse {
    my $self = shift;
    my $value = shift;

    my ( $source, $path ) = @$value{qw/ source path /};
    my $target = $self->into->file( $path );

    return if $self->_seen->{ "$target" };

    $self->_seen->{ "$target" } = 1;

    die "*** Invalid asset \"$source\" (not a file or does not exist)" unless -f $source;

    my @item;
    push @item, path => $path, source => $source, target => $target;
    push @item, attachment => 1 if $value->{ attachment };

    return App::collate::Assets::WriteManifest::Item->new( @item );
}

package App::collate::Assets::WriteManifest::Item;

use strict;
use warnings;

use App::collate::Moose;

has path => qw/ is ro required 1 isa Str /;
has_file [qw/ source target /] => qw/ is ro required 1 /;
has attachment => qw/ is ro /;

package App::collate::Assets::ImportManifest;

use strict;
use warnings;

use Any::Moose;

with 'App::collate::Assets::ManifestRole';

sub parse {
    my $self = shift;
    my $assets = shift;

    if ( ref $assets eq '' ) {
        die "Invalid assets" unless defined $assets && length $assets;
    }
    else {
        die "Invalid assets ($assets)" unless blessed $assets && $assets->isa( 'App::collate::Assets' );
    }

    return $assets;
}

1;
