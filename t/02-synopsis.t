#!/usr/bin/env perl
use strict;
use warnings;
use Test::Most;

use App::assetize::Assets;

my $assets = App::assetize::Assets->new;

$assets->manifest->add( 'jquery-ui/jquery-ui.js' );
$assets->manifest->add( 'jquery-ui/jquery-ui.css' );
$assets->manifest->add( '    ' );
$assets->manifest->add( undef );
cmp_deeply( [ $assets->manifest->all ], [qw[
    jquery-ui/jquery-ui.js
    jquery-ui/jquery-ui.css
]] );

done_testing;
