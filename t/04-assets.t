#!/usr/bin/env perl
use strict;
use warnings;
use Test::Most;

use File::Temp qw/ tempdir /;

use App::collate;

my ( $assets, $require_assets, $manifest, @manifest, $tmp );

$tmp = tempdir;

$assets = App::collate->assets(
    base => 't/assets',
    include => <<_END_,
jquery-ui/jquery-ui.js
jquery-ui/base/jquery-ui.css
_END_
);

cmp_deeply( [ $assets->manifest->all ], [qw[
    jquery-ui/jquery-ui.js
    jquery-ui/base/jquery-ui.css
]] );

done_testing;
