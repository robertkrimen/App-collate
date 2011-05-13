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

__END__

=head1 SYNOPSIS

TODO Talk about include, attach, and import

1. Create a collection of common assets (jQuery, underscore, Zero Clipboard, etc.)  and (for this example) put them in ~/assets/:

Declaring an asset bundle does not automatically include it, but does make it available for import

    #!/usr/bin/env perl

    use strict;
    use warnings;

    sub {
        my ( $collate ) = @_;

        $collate->declare( 'underscore' =>
            include => <<_END_,
    underscore.js
    _END_
        );
        
        $collate->declare( 'jquery' =>
            include => <<_END_,
    jquery.js
    _END_
        );
        
        $collate->declare( 'jquery-ui' =>
            import => <<_END_,
    jquery
    _END_
            include => <<_END_,
    jquery-ui/jquery-ui.js
    jquery-ui/base/jquery-ui.css
    _END_
            attach => <<_END_,
    jquery-ui/base
    _END_
        );


        $collate->declare( 'zeroclipboard' =>
            include => <<_END_,
    zeroclipboard/ZeroClipboard.js
    _END_
            attach => <<_END_,
    zeroclipboard/ZeroClipboard.swf
    _END_
        );

        $collate->declare( 'tipsy' =>
            import => <<_END_,
    jquery
    _END_
            include => <<_END_,
    tipsy/jquery.tipsy.js
    tipsy/tipsy.css
    _END_
        );
    };


2. Create ~/.collaterc:

    #!/usr/bin/env perl 

    use strict;
    use warnings;

    sub {
        my ( $collate ) = @_;

        # Use the 'yuicompressor' command to compress with YUI Compressor
        $collate->setup_yuicompressor( 'yuicompressor' );

        $assets->load( "~/assets/collate.assets" );

    };

3. Create app.assets in your (web) application directory:

This file will take imported assets and write them out to the specified directory, optionally compressing them

    #!/usr/bin/env perl

    use strict;
    use warnings;

    sub {
        my ( $collate ) = @_;

        $collate->import( <<_END_ );
jquery
jquery-ui
_END_

        $collate->include( <<_END_ );
    assets/app.js
    _END_

        $collate->write( 'assets' );

    }

4. Run the C<collate> command from the shell in the same directory as C<app.assets>:

    $ collate

You should end up with a file hiearchy that looks something like this:

    assets/jquery.js
    assets/jquery-ui/jquery-ui.js
    assets/app.js
