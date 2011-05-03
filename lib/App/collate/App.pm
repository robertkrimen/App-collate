package App::collate::App;

use strict;
use warnings;

use Getopt::Usaginator <<_END_;
    
    Usage: collate [--file <file>]

_END_

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

    my $code = do $file;
    usage "*** Invalid file ($file): Unable to read/execute: $!" if $!;
    usage "*** Invalid file ($file): Unable to execute: $@" if $@;
    usage "*** Invalid return value ($code) from file ($file): Should be a subroutine (CODE reference)" unless ref $code eq 'CODE';

    my $assets = App::collate::AppAPI->new( app => $self );

    $code->( $assets );
}

package App::collate::AppAPI;

use Any::Moose;

has app => qw/ is ro required 1 isa App::collate::App /;

1;
