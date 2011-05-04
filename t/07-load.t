#!/usr/bin/env perl
use strict;
use warnings;
use Test::Most;

use File::Temp qw/ tempdir /;

use App::collate::Script;

my ( $script, $assets, $manifest, @manifest, $tmp );

$tmp = tempdir;
$t::tmp = 'trial';

$script = App::collate::Script->new( file => Path::Class::file( 't/assets/empty.assets' ) );
$script->_run;

$script->load( 't/assets/multi.assets' );
ok( $script->repository->has( 'jquery' ) );
ok( $script->repository->has( 'jquery-ui' ) );
ok( $script->repository->has( 'qunit' ) );

$script->import( <<_END_ );
qunit
_END_

$manifest = $script->assets->write_manifest( into => $tmp, repository => $script->repository );

cmp_deeply( [ map { $_->path } $manifest->all ], [qw[
    jquery.js
    jquery-ui/jquery-ui.js
    jquery-ui/base/jquery-ui.css
    qunit/qunit.js
    qunit/qunit.css
]] );

#$manifest = $script->assets->write_manifest( into => $tmp, repository => $script->repository );

#cmp_deeply( [ map { $_->path } $manifest->all ], [qw[
#    jquery-ui/jquery-ui.js
#    jquery-ui/base/jquery-ui.css
#    app.css
#    app.js
#]] );

#$t::tmp = Path::Class::dir( $t::tmp );

#ok( -s $t::tmp->file(qw[ app.css ]) );
#ok( -s $t::tmp->file(qw[ app.js ]) );
#ok( -s $t::tmp->file(qw[ jquery-ui/jquery-ui.js ]) );
#ok( -s $t::tmp->file(qw[ jquery-ui/base/jquery-ui.css ]) );

done_testing;

