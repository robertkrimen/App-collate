package App::collate::Compressor;

use Path::Class;
use File::Temp();

use App::collate::Util;

use Any::Moose;

sub from {
    my $class = shift;
    my $cfg = shift;

    die "*** Missing compressor configuration" unless $cfg;

    my ( $js, $css );
    if ( ref $cfg eq 'HASH' ) {
        if ( $cfg->{ via } )    { $js = $css = $cfg }
        else                    { ( $js, $css ) = @$cfg{qw/ js css /} }
    }
    else {
        die "*** Invalid compressor configuration ($cfg)" 
    }

    return $class->new( js => $js, css => $css );
}

has [qw/ js css /] => qw/ is rw /;

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

    if ( $method->{via} eq 'yuicompressor' ) {
        App::collate->yuicompressor( with => 'yuicompressor', input => "$tmp", output => "$file" );
    }
    elsif ( $method->{via} eq 'closure' ) {
        App::collate->closure_compiler( with => 'closure', input => "$tmp", output => "$file" );
    }

    return $file;
}

1;
