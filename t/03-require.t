#!/usr/bin/env perl
use strict;
use warnings;
use Test::Most;

use File::Temp qw/ tempdir /;

use App::assetize::Assets;

my ( $assets, $require_assets, $manifest, @manifest, $tmp );

$tmp = tempdir;

$assets = App::assetize::Assets->new( base => 't/assets' );
$require_assets = App::assetize::Assets->new( base => 't/assets' );

$assets->manifest->add( 'jquery-ui/jquery-ui.js' );
$require_assets->manifest->add( 'jquery-ui/base/jquery-ui.css' );
$require_assets->attach_manifest->add( 'jquery-ui/base => base' );

$assets->require_manifest->add( $require_assets );

@manifest = $assets->write_manifest( into => $tmp )->all;
is( scalar @manifest, 5 );
is( $manifest[ 0 ]->source, 't/assets/jquery-ui/base/jquery-ui.css' );
is( $manifest[ 1 ]->source, 't/assets/jquery-ui/base/0.png' );
ok( $manifest[ 1 ]->attachment );
is( $manifest[ 2 ]->source, 't/assets/jquery-ui/base/1.jpg' );
ok( $manifest[ 2 ]->attachment );
is( $manifest[ 3 ]->source, 't/assets/jquery-ui/base/2.gif' );
ok( $manifest[ 3 ]->attachment );
is( $manifest[ 4 ]->source, 't/assets/jquery-ui/jquery-ui.js' );



done_testing;
