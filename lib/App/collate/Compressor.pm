package App::collate::Compressor;

use Path::Class;
use File::Temp();

use App::collate::Util;

use Any::Moose;

has [qw/ js css /] => qw/ is rw /;

sub resolve_cfg {
    my $class = shift;
    my $cfg = shift;

    my $cfg_result;

    if ( ref $cfg eq 'HASH' ) {
        my $method = $cfg->{ method };
        die "*** Missing compression method in $cfg" if empty $method;
        $method = lc $method;

        if ( $method eq 'yuicompressor' ) {
            $cfg_result = $class->resolve_yuicompressor( $cfg );
        }
        elsif ( $method =~ m/^closure(?:[_-]?compiler)?$/ ) {
            $cfg_result = $class->resolve_closure_compiler( $cfg );
        }
        else {
            die "*** Invalid compressor method ($method)" 
        }
    }
    elsif ( ref $cfg eq '' ) {
        if ( $cfg =~ s/^yuicompressor://i || $cfg =~ m/yuicompressor/i ) {
            $cfg_result = $class->resolve_yuicompressor( $cfg );
        }
        elsif ( $cfg =~ s/^closure(?:[_-]?compiler)?://i || $cfg =~ m/(?:compiler\.jar|closure)/i ) {
            $cfg_result = $class->resolve_closure_compiler( $cfg );
        }
        else {
            die "*** Invalid compressor configuration ($cfg)" 
        }
    }
    else {
        die "*** Invalid compressor configuration ($cfg)" 
    }

    return $cfg_result;
}

sub from {
    my $class = shift;
    my $cfg = shift;

    die "*** Missing compressor configuration" unless $cfg;

    my $compressor = $class->new;

    if ( ref $cfg eq 'HASH' ) {
        for my $type (qw/ js css /) {
            $compressor->$type( $class->resolve_cfg( $cfg->{ $type } ) );
        }
    }
    elsif ( ref $cfg eq '' ) {
        if ( $cfg =~ s/^yuicompressor:// || $cfg =~ m/yuicompressor/ ) {
            $compressor->setup_yuicompressor( $cfg );
        }
        elsif ( $cfg =~ s/^closure:// || $cfg =~ m/(?:compiler\.jar|closure)/ ) {
            $compressor->setup_closure_compiler( $cfg );
        }
        else {
            die "*** Invalid compressor configuration ($cfg)" 
        }
    }
    else {
        die "*** Invalid compressor configuration ($cfg)" 
    }

    return $compressor;
}

sub resolve_jar_cfg {
    my $self = shift;
    my @options;

    if ( @_ % 2 ) {
        my $value = shift @_;
        if ( ref $value eq 'HASH' ) {
            push @options, %$value;
        }
        else {
            $value = '' if empty $value;
            warn $value;
            if ( $value =~ m/\.jar$/ ) {
                push @options, jar => $value;
            }
            else {
                push @options, run => $value;
            }
        }
    }

    return { @options, @_ };
}

sub resolve_yuicompressor_cfg {
    my $self = shift;

    return $self->resolve_jar_cfg( @_, method => 'yuicompressor' );
}

sub resolve_closure_compiler_cfg {
    my $self = shift;

    return $self->resolve_jar_cfg( @_, method => 'compiler_compiler' );
}

sub setup_yuicompressor {
    my $self = shift;

    my $options = $self->resolve_yuicompressor_cfg( @_ );

    my $for = delete $options->{ for };
    $for = '*' unless defined $for;

    $self->js( $options ) if $for eq '*' || $for eq 'js';
    $self->css( $options ) if $for eq '*' || $for eq 'css';
}

sub setup_closure_compiler {
    my $self = shift;

    my $options = $self->resolve_closure_compiler_cfg( @_ );

    $self->js( $options );
}

sub compress {
    my $self = shift;
    my %arguments = @_;

    my ( $type, $list, $into, $name ) = @arguments{qw/ type list into name /};

    return unless $list && @$list;

    $type = lc $type;
    die "*** Invalid type ($type)" unless $type eq 'js' || $type eq 'css';

    $into = dir $into;

    my $content;
    if ( $type eq 'js' )    { $content = join ";\n", map { scalar $_->source->slurp } @$list }
    else                    { $content = join "\n", map { scalar $_->source->slurp } @$list }

    my $file = asset_file type => $type, base => $into, name => $name, content => \$content;
    $file->parent->mkpath;

    my $tmp = File::Temp->new( suffix => ".$type" );
    $tmp->print( $content );

    my $method = $self->$type;

    die "*** Missing compression method" if empty $method;

    if ( $method->{ method } eq 'yuicompressor' ) {
        App::collate->yuicompress( %$method, input => "$tmp", output => "$file" );
    }
    elsif ( $method->{ method } eq 'closure_compiler' ) {
        App::collate->closure_compile( %$method, input => "$tmp", output => "$file" );
    }
    else {
        die "*** Invalid compression method ($method)";
    }

    return $file;
}

1;
