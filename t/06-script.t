#!/usr/bin/env perl
use strict;
use warnings;
use Test::Most;

use App::collate::Script;

my ( $script, $assets, $manifest, @manifest, $tmp );

$script = App::collate::Script->new( file => Path::Class::file( 't/assets/app.assets' ) );
$script->_run;

ok( $script->repository->has( 'jquery-ui' ) );

cmp_deeply( [ $script->repository->assets( 'jquery-ui' )->manifest->all ], [qw[
    jquery-ui/jquery-ui.js
    jquery-ui/base/jquery-ui.css
]] );

done_testing;

