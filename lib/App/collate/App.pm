package App::collate::App;

use strict;
use warnings;

use Getopt::Usaginator <<_END_;
    
    Usage: collate [--file <file>]

_END_
use Path::Class;
use File::HomeDir();

use App::collate::Repository;
use App::collate::Script;
use App::collate::Util;

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

    my $repository = App::collate::Repository->new;

    my $collaterc;
    {
        if ( ! empty( $collaterc = $ENV{ COLLATERC } ) ) {
        }
        elsif ( defined( my $home = File::HomeDir->my_home ) ) {
            $collaterc = file $home, '.collaterc';
        }
    }

    if ( ! empty $collaterc && $collaterc ne '-' && -f $collaterc ) {
        my $script = App::collate::Script->new( file => file( $collaterc ), repository => $repository );
        $script->_run;
    }

    my $script = App::collate::Script->new( file => file( $file ), repository => $repository );
    $script->_run;
}

1;
