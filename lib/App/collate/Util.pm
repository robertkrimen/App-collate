package App::collate::Util;

use strict;
use warnings;

use Package::Pkg;
use String::Util qw/ trim /;
use Path::Class;
use Digest::SHA qw/ sha1_hex /;

pkg->export(qw/ each_trimmed_line expand_path asset_file empty join_slash_path /);

sub empty ($) {
    return not defined $_[0] && length $_[0];
}

sub asset_file {
    my %options = @_;

    my ( $type, $name, $base, $content ) =
        map { defined $_ ? $_ : '' } @options{qw/ type name base content /};

    $name = 'asset' unless length $name;
    $name = join '_', $name, sha1_hex $$content;

    $base = dir $base;

    return $base->file( "$name.$type" );
}

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

    $path0 = '' if empty $path0;
    my $path1 = "$path0";

    if ( $path1 =~ m{^(?:/)} ) {
    }
    elsif ( $path1 =~ s{^~/}{/} ) {
        $path1 = join '', $ENV{ HOME }, $path1;
    }
    elsif ( defined $base ) {
        $path1 = file( $base, $path1 );
    }

    $path1 =~ s/^\.\///;

    return "$path1";
}

sub join_slash_path {
    my $path = join '/', grep { defined $_ && length $_ } @_;
    $path =~ s/\/+/\//;
    $path =~ s/^\.\///;
    return $path;
}

sub rewrite_content {
    my $self = shift;
    my $input = shift;
    my %arguments = @_;

    my @output;
    my @input = ref $input eq 'ARRAY' ? @$input : split m/\n/, $input;

    my %substitute;
    for (qw/ js css /) {
        next if empty( my $file = $arguments{ $_ } );
        $substitute{ $_ } = join_slash_path $arguments{ path }, $file->basename;
    }

    my $rewrite;
    while ( @input ) {
        local $_ = shift @input;

        if ( $rewrite ) {
            undef $rewrite if m/^\s*<!--\s*\]\s*-->\s*$/;
        }
        elsif ( m/^\s*<!--\s*collate:(js|css)\s*\[\s*-->\s*$/i ) {
            $rewrite = 1;
            my $type = lc $1;
            if ( $type eq 'js' && $substitute{ js } ) {
                push @output, qq!<script type="text/javascript" src="$substitute{js}"></script>\n!;
            }
            elsif ( $substitute{ css } ) {
                push @output, qq!<link rel="stylesheet" href="$substitute{css}" />\n!;
            }
        }
        else {
            push @output, $_;
        }
    }

    return ref $input eq 'ARRAY' ? @output : join "\n", @output;
}

1;
