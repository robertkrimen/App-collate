#!/usr/bin/env perl
use strict;
use warnings;
use Test::Most;

use File::Temp qw/ tempdir /;

use App::collate::Script;

my ( $script, $assets, $manifest, @manifest, $tmp );

$tmp = tempdir;

$script = App::collate::Script->new( file => Path::Class::file( 't/assets/app.assets' ) );
$script->_run;

ok( $script->repository->has( 'jquery-ui' ) );

cmp_deeply( [ $script->repository->assets( 'jquery-ui' )->manifest->all ], [qw[
    jquery-ui/jquery-ui.js
    jquery-ui/base/jquery-ui.css
]] );

$manifest = $script->assets->write_manifest( into => $tmp, repository => $script->repository );

cmp_deeply( [ map { $_->path } $manifest->all ], [qw[
    jquery-ui/jquery-ui.js
    jquery-ui/base/jquery-ui.css
    app.css
    app.js
]] );

done_testing;

