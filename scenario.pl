#!/usr/bin/env perl

# app.assets

sub {
    my ( $assets ) = @_;

    $assets->declare( 'prettify' => 
        include => <<_END_,
prettify.js
prettify.css
_END_
    );

    $assets->declare( 'prettify-all' => 
        include => <<_END_,
prettify/prettify.js
prettify/prettify.css
_END_
    );

    $assets->declare( 'jquery-ui' =>
        include => <<_END_,
jquery-ui/jquery-ui.js
jquery-ui/base/jquery-ui.css
_END_
        attach => <<_END_,
jquery-ui/base/ => base/
_END_
        import => <<_END_,
jquery
_END_
    );
}

# Typical client (condor)

sub {

    my ( $assets ) = @_;

    $assets->import( <<_END_ );
jquery
jquery-ui
_END_

    $assets->include( <<_END_ );
assets/condor.js
assets/condor.css
_END_

    $assets->write( 'assets' );
    $assets->write( 'assets', compress => 1 );
}

# Typical library (DOMite)

sub {

    my ( $assets ) = @_;

    $assets->name( 'DOMite' );

    $assets->import( <<_END_ );
underscore
jquery
_END_

    $assets->include( <<_END_ );
assets/DOMite.js
_END_

    $assets->write( 'assets' );
    $assets->write( 'assets', compress => 1 );
}

# Repository (repository.assets)

sub {

    my ( $assets ) = @_;

    $assets->load( '~/develop/assets/export.assets' );
    $assets->load( '~/develop/DOMite-js/export.assets' );

}

