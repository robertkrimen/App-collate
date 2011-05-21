package App::collate::Script;

use Path::Class;

use App::collate::Compressor;
use App::collate::Repository;
use App::collate::Assets;
use App::collate::Util;

use App::collate::Moose;

has_file file => qw/ is ro required 1 /;

has compressor => qw/ is rw lazy_build 1 isa App::collate::Compressor /, handles => [qw/
    setup_yuicompressor
    setup_closure_compiler
/];
sub _build_compressor {
    return App::collate::Compressor->new;
}

has repository => qw/ is rw lazy_build 1 isa App::collate::Repository /;
sub _build_repository {
    return App::collate::Repository->new;
}

has_dir _base => qw/ is rw lazy_build 1 /;
sub _build__base {
    my $self = shift;
    return $self->file->parent;
}

sub rebase {
    my $self = shift;
    my $path = shift;
    $self->_base( expand_path( $path, $self->_base ) );
    $self->assets->base( $self->_base );
}

has load_only => qw/ is ro isa Bool /;

has _name => qw/ is rw isa Str predicate has_name /;
sub name {
    my $self = shift;
    return $self->_name unless @_;
    if ( $self->has_name ) {
        die "*** Already named assets: ", $self->_name;
    }
    my $name = shift;
    if ( $self->_has_assets ) {
        $self->repository->assets( $name => $self->assets );
    }
    $self->_name( $name );
    return $name;
}


has assets => qw/ is rw isa App::collate::Assets lazy_build 1 predicate has_assets /;
sub _build_assets {
    my $self = shift;
    my $assets = App::collate::Assets->new( base => $self->_base );
    if ( $self->has_name ) {
        $self->repository->assets( $self->_name => $assets );
    }
    return $assets;
}

sub load {
    my $self = shift;
    my $file = shift;

    $file = expand_path( $file, $self->_base );

    my $script = ( ref $self )->new( repository => $self->repository, load_only => 1, file => $file );
    $script->_run;
}

sub _run {
    my $self = shift;

    my $file = $self->file;
    # TODO "do" in an isolated package
    my $code = do "$file";
    die "*** Invalid file ($file): Unable to read/execute: $!" if $!;
    die "*** Invalid file ($file): Unable to execute: $@" if $@;
    die "*** Invalid return value ($code) from file ($file): Should be a subroutine (CODE reference)" unless ref $code eq 'CODE';

    $code->( $self );
}

sub include {
    my $self = shift;
    $self->assets->include( @_ );
}

sub attach {
    my $self = shift;
    $self->assets->attach( @_ );
}

sub import {
    my $self = shift;
    return unless ref $self;
    $self->assets->import( @_ );
}

sub declare {
    my $self = shift;
    my $name = shift;

    my $assets = $self->repository->declare( $name, base => $self->_base.'', @_ );
    return $assets;
}

use File::Copy qw/ copy /;
use File::Temp();

sub write {
    my $self = shift;
    return if $self->load_only;

    my $into = Path::Class::dir( expand_path( shift, $self->_base ) );
    my %options = @_;

    my $write_manifest = $self->assets->write_manifest( into => $into, repository => $self->repository );
    $write_manifest->write( rewrite_base => $self->_base, compressor => $self->compressor, %options );

    return $write_manifest;
}

1;
