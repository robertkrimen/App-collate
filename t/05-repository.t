#!/usr/bin/env perl
use strict;
use warnings;
use Test::Most;

use File::Temp qw/ tempdir /;

use App::collate::Repository;

my ( $repository, $assets, $manifest, @manifest, $tmp );

$tmp = tempdir;

$repository = App::collate::Repository->new;

$assets = $repository->declare( 'jquery-ui' =>
    base => 't/assets',
    include => <<_END_,
jquery-ui/jquery-ui.js
jquery-ui/base/jquery-ui.css
_END_
);

ok( $repository->has( 'jquery-ui' ) );

cmp_deeply( [ $repository->assets( 'jquery-ui' )->manifest->all ], [qw[
    jquery-ui/jquery-ui.js
    jquery-ui/base/jquery-ui.css
]] );

done_testing;
