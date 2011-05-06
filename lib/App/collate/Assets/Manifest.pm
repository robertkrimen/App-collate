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

use App::collate::Util;
use App::collate::Compressor;

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

sub sifted {
    my $self = shift;

    my %sifted;
    $sifted{ $_ } = [] for qw/ js css attachment /;

    for my $item ( $self->all ) {
        push @{ $sifted{ $item->type } }, $item;
    }

    return %sifted;
}

sub write {
    my $self = shift;
    my %options = @_;

    my $into = $self->into;

    if ( ! $options{ compressed } ) {
        $_->write for $self->all;
    }
    else {
        my %sifted = $self->sifted;

        my $compressor = App::collate::Compressor->from( $options{ compressed } );

        for my $item (@{ $sifted{ attachment } }) {
            $item->write;
        }

        my $js_file = $compressor->compress( type => 'js', list => $sifted{ js }, into => $into, name => $options{ name } );
        my $css_file = $compressor->compress( type => 'css', list => $sifted{ css }, into => $into, name => $options{ name } );

        if ( $options{ rewrite } ) {

            my $rewrite_base = $options{ rewrite_base };

            for my $rewrite ( @{ $options{ rewrite } } ) {
                my ( $from, $to, $path ) = @$rewrite;
                $from = Path::Class::file( expand_path $from, $rewrite_base );
                $to = Path::Class::file( expand_path $to, $rewrite_base );
                $to->parent->mkpath;
                $to->openw->print(
                    App::collate::Util->rewrite_content( [ $from->slurp ], path => $path, js => $js_file, css => $css_file ) );
            }
        }
    }
}

package App::collate::Assets::WriteManifest::Item;

use strict;
use warnings;

use File::Copy qw/ copy /;

use App::collate::Moose;

has path => qw/ is ro required 1 isa Str /;
has_file [qw/ source target /] => qw/ is ro required 1 /;
has type => qw/ is ro isa Str lazy_build 1 /;
sub _build_type {
    my $self = shift;
    return 'attachment' if $self->attachment;
    my $path = $self->path;
    return lc $1 if $path =~ m/\.(js|css)/i;
    die "*** Invalid item ($path): Not .js, .css, or attachment";
}

has attachment => qw/ is ro /;

sub write {
    my $self = shift;
    $self->target->parent->mkpath;
    copy $self->source, $self->target;
}

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
