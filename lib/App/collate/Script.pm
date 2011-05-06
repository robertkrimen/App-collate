package App::collate::Script;

use Path::Class;

use App::collate::Repository;
use App::collate::Assets;
use App::collate::Util;

use App::collate::Moose;

has_file file => qw/ is ro required 1 /;

has repository => qw/ is rw lazy_build 1 isa App::collate::Repository /;
sub _build_repository {
    return App::collate::Repository->new;
}

has_dir _base => qw/ is rw lazy_build 1 /;
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

    $file = expand_path( $file, $self->_base );

    my $script = ( ref $self )->new( repository => $self->repository, load_only => 1, file => $file );
    $script->_run;
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

    if ( ! $options{ compressed } ) {
        for my $item ( $write_manifest->all ) {
            $item->target->parent->mkpath;
            copy $item->source, $item->target;
        }
    }
    else {
        my ( $js, $css, $js_file, $css_file );

        {
            my ( @js, @css );

            for my $item ( $write_manifest->all ) {
                if ( $item->path =~ m/\.js$/ ) {
                    push @js, join '', ";\n", scalar $item->source->slurp;
                }
                elsif ( $item->path =~ m/\.css$/ ) {
                    push @css, join '', "\n", scalar $item->source->slurp;
                }
                else {
                    $item->target->parent->mkpath;
                    copy $item->source, $item->target;
                }
            }

            $js = join '', @js;
            $css = join '', @css;
        }

        $js_file = asset_file type => 'js', base => $into, name => $options{ name }, content => \$js;
        $css_file = asset_file type => 'css', base => $into, name => $options{ name }, content => \$css;

        if ( defined $js ) {
            my $tmp = File::Temp->new( suffix => '.js' );
            $tmp->print( $js );
            $js_file->openw->print( $js );
            #App::collate->yuicompressor( with => 'yuicompressor', input => "$tmp", output => "$js_file" );
        }

        if ( defined $css ) {
            my $tmp = File::Temp->new( suffix => '.css' );
            $tmp->print( $css );
            $css_file->openw->print( $css );
            #App::collate->yuicompressor( with => 'yuicompressor', input => "$tmp", output => "$css_file" );
        }

        if ( $options{ rewrite } ) {

            for my $rewrite ( @{ $options{ rewrite } } ) {
                my ( $from, $to, $path ) = @$rewrite;
                $from = Path::Class::file( expand_path $from, $self->_base );
                $to = Path::Class::file( expand_path $to, $self->_base );
                my @from = $from->slurp;
                my @to;

                my $replace;
                while ( @from ) {
                    my $line = shift @from;
                    if ( $replace ) {
                        if ( $line =~ m/^\s*<!--\s*\]\s*-->\s*$/ ) {
                            if ( $replace eq 'js' ) {
                                push @to, qq!<script type="text/javascript" src="$js_file"></script>\n!;
                            }
                            else {
                                push @to, qq!<link rel="stylesheet" href="$css_file" />\n!;
                            }
                            undef $replace;
                        }
                    }
                    elsif ( $line =~ m/^\s*<!--\s*collate:(js|css)\s*\[\s*-->\s*$/ ) {
                        $replace = $1;
                    }
                    else {
                        push @to, $line;
                    }
                }

                $to->openw->print( join '', @to );
            }
        }
    }

    return $write_manifest;
}

1;
