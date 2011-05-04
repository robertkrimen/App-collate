package App::collate::Script;

use App::collate::Repository;
use App::collate::Assets;

use Any::Moose;

has file => qw/ is ro required 1 isa Path::Class::File /;

has repository => qw/ is rw lazy_build 1 isa App::collate::Repository /;
sub _build_repository {
    return App::collate::Repository->new;
}

has _base => qw/ is rw isa Path::Class::Dir lazy_build 1 /;
sub _build__base {
    my $self = shift;
    return $self->file->parent;
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
    my $assets = App::collate::Assets->new( base => $self->_base.'' );
    if ( $self->has_name ) {
        $self->repository->assets( $self->_name => $assets );
    }
    return $assets;
}

sub load {
    my $self = shift;
    my $file = shift;

    my $api = ( ref $self )->new( app => $self->app, repository => $self->repository, load_only => 1, file => Path::Class::File->new( $file ) );
}

sub _run {
    my $self = shift;

    my $file = $self->file;
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

    # TODO Do $repository->asset( ... ) substitution on import

    my $assets = $self->repository->declare( $name, base => $self->_base.'', @_ );
    return $assets;
}

sub write {
    my $self = shift;

    return if $self->load_only;
}

1;
