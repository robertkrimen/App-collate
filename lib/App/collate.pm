package App::collate;
# ABSTRACT: Collate .js and .css assets

use strict;
use warnings;

use IPC::System::Simple();

use App::collate::Util;
require App::collate::Assets;

sub yuicompress {
    return shift->yuicompressor( @_ );
}

sub yuicompressor {
    my $self = shift;
    my %options = @_;

    my $command = $self->yuicompressor_command( %options );
    IPC::System::Simple::run( $command );
}

sub yuicompressor_command {
    my $self = shift;
    my %options = @_;

    my ( $run, $jar, $java, $input, $output, $type ) = 
        map { defined $_ ? $_ : '' } @options{ qw/ run jar java input output type / };

    die "*** Missing input file" if empty $input;
    die "*** Missing output file" if empty $output;

    $java = 'java' if empty $java;

    my @command;
    if ( $jar ) {
        push @command, "$java -jar $jar";
    }
    else {
        die "*** Missing yuicompressor or yuicompressor.jar" unless length $run;
        push @command, "$run";
    }

    push @command, "--type $type" if length $type;
    push @command, "-o $output";
    push @command, "$input";

    return join ' ', @command;
}

sub closure_compile {
    return shift->closure_compiler( @_ );
}

sub closure_compiler {
    my $self = shift;
    my %options = @_;

    my $command = $self->closure_compiler_command( %options );
    IPC::System::Simple::run( $command );
}

sub closure_compiler_command {
    my $self = shift;
    my %options = @_;

    my ( $run, $jar, $java, $input, $output ) =
        map { defined $_ ? $_ : '' } @options{ qw/ run jar java input output / };

    die "*** Missing input file" if empty $input;
    die "*** Missing output file" if empty $output;

    $java = 'java' if empty $java;

    my @command;
    if ( $jar ) {
        push @command, "$java -jar $jar";
    }
    else {
        die "*** Missing closure or compiler.jar (closure compiler)" unless length $run;
        push @command, "$run";
    }

    push @command, "--js $input";
    push @command, "--js_output_file $output";
    push @command, "--third_party";

    return join ' ', @command;
}

sub assets {
    my $self = shift;
    my %options = @_;

    my $assets = App::collate::Assets->new( base => $options{ base } );

    $assets->import( $options{ import } );
    $assets->include( $options{ include } );
    $assets->attach( $options{ attach } );

    return $assets;
}

1;
