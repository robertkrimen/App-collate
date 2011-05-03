package App::collate::App;

use strict;
use warnings;

use Getopt::Usaginator <<_END_;
    
    Usage: collate [--file <file>]

_END_
use Path::Class();

use Any::Moose;

sub run {
    my $self = shift;
    return $self->new->run( @_ ) unless ref $self;
    my @arguments = @_;

    my $file = 'app.assets';
    Getopt::Usaginator->parse( \@arguments,
        'file=s' => \$file,
    );

    if ( ! -f $file ) {
        usage "*** Invalid file ($file): Not a file or does not exist";
    }

    my $script = App::collate::Script->new( file => Path::Class::file( $file ) );
    $script->_run;
}

