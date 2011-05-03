#!/usr/bin/env perl
use strict;
use warnings;
use Test::Most;

use File::Temp qw/ tempdir /;

use App::collate::Assets;

my ( $assets, $manifest, $tmp );

$tmp = tempdir;

$assets = App::collate::Assets->new( base => 't/assets' );

$assets->manifest->add( 'jquery-ui/jquery-ui.js' );
$assets->manifest->add( 'jquery-ui/base/jquery-ui.css' );
$assets->manifest->add( '    ' );
$assets->manifest->add( undef );
cmp_deeply( [ $assets->manifest->all ], [qw[
    jquery-ui/jquery-ui.js
    jquery-ui/base/jquery-ui.css
]] );

cmp_deeply( [ $assets->attach_manifest->all ], [] );
cmp_deeply( [ $assets->import_manifest->all ], [] );

$assets->attach_manifest->add( 'jquery-ui/base => base' );
cmp_deeply( [ map { $_->path } $assets->attach_manifest->all ], [qw[
    jquery-ui/base
]] );

$assets->write_manifest( into => $tmp );

done_testing;
