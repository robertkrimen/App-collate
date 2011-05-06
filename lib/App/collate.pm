package App::collate;
# ABSTRACT: Collate .js and .css assets

use strict;
use warnings;

use IPC::System::Simple();

require App::collate::Assets;

sub yuicompressor {
    my $self = shift;
    my %options = @_;

    my $command = $self->yuicompressor_command( %options );
    IPC::System::Simple::run( $command );
}

sub yuicompressor_command {
    my $self = shift;
    my %options = @_;

    my ( $with, $java, $input, $output, $type ) = 
        map { defined $_ ? $_ : '' } @options{ qw/ with java input output type / };

    die "*** Missing yuicompress or yuicompress.jar" unless length $with;
    my $jar = $with =~ m/\.jar$/;
    die "*** Missing java for yuicompress ($with)" if $jar && ! length $java;
    die "*** Missing input file" unless length $input;
    die "*** Missing output file" unless length $output;

    my @command;
    if ( $jar ) { push @command, "$java -jar $with" }
    else        { push @command, "$with" }

    push @command, "--type $type" if length $type;
    push @command, "-o $output";
    push @command, "$input";

    return join ' ', @command;
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

    my ( $with, $java, $input, $output ) =
        map { defined $_ ? $_ : '' } @options{ qw/ with java input output / };

    die "*** Missing compiler.jar" unless length $with;
    my $jar = $with =~ m/\.jar$/;
    die "*** Missing java for compiler.jar ($with)" if $jar && ! length $java;
    die "*** Missing input file" unless length $input;
    die "*** Missing output file" unless length $output;

    my @command;
    if ( $jar ) { push @command, "$java -jar $with" }
    else        { push @command, "$with" }

    push @command, "--js $input";
    push @command, "--js_output_file $output";

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
