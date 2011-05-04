#!/usr/bin/env perl
use strict;
use warnings;
use Test::Most;
use Carp::Always;

use File::Temp qw/ tempdir /;

use App::collate::Script;

my ( $script, $assets, $manifest, @manifest, $tmp );

$tmp = tempdir;
$t::tmp = $tmp;

$script = App::collate::Script->new( file => Path::Class::file( 't/assets/test/app.assets' ) );
$script->load( 't/assets/multi.assets' );
$script->_run;
$script->import( <<_END_ );
qunit
_END_

$script->write( $t::tmp );

$t::tmp = Path::Class::dir( $t::tmp );

ok( -s $t::tmp->file(qw[ jquery.js ]) );
ok( -s $t::tmp->file(qw[ jquery-ui/jquery-ui.js ]) );
ok( -s $t::tmp->file(qw[ jquery-ui/base/jquery-ui.css ]) );

done_testing;

