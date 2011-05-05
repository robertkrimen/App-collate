package App::collate::Util;

use strict;
use warnings;

use Package::Pkg;
use String::Util qw/ trim /;
use Path::Class;

pkg->export(qw/ each_trimmed_line expand_path /);

sub each_trimmed_line ($$) {
    my $source = shift;
    my $iterator = shift;

    return unless defined $source;

    for my $line ( split m/\n/, $source ) {
        $line = trim $line;
        $iterator->( $line );
    }
}

sub expand_path ($;$) {
    my $path0 = shift;
    my $base = shift;

    my $path1 = "$path0";

    if ( $path1 =~ m{^(?:/|\./)} ) {
    }
    elsif ( $path1 =~ s{^~/}{/} ) {
        $path1 = join '', $ENV{ HOME }, $path1;
    }
    elsif ( defined $base ) {
        $path1 = file( $base, $path1 );
    }

    return "$path1";
}

1;
