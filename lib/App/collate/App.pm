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

    my $repository = App::collate::Repository->new;

    if ( $ENV{ COLLATE_REPOSITORY } ) {
        my $script = App::collate::Script->new( file => Path::Class::file( $ENV{ COLLATE_REPOSITORY } ), load_only => 1, repository => $repository );
        $script->_run;
    }

    my $script = App::collate::Script->new( file => Path::Class::file( $file ), repository => $repository );
    $script->_run;
}

