#!/usr/bin/env perl
use strict;
use warnings;
use Test::Most;

use File::Temp qw/ tempdir /;

use App::assetize;

my ( $assets, $require_assets, $manifest, @manifest, $tmp );

$tmp = tempdir;

$assets = App::assetize->assets( base => 't/assets',
    manifest => <<_END_,
jquery-ui/jquery-ui.js
jquery-ui/base/jquery-ui.css
_END_
);

cmp_deeply( [ $assets->manifest->all ], [qw[
    jquery-ui/jquery-ui.js
    jquery-ui/base/jquery-ui.css
]] );

done_testing;
