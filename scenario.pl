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

sub {

    my ( $assets ) = @_;

    $assets->declare( 'condor' =>
        import => <<_END_,
jquery
jquery-ui
_END_
        include => 
}

# Repository (repository.assets)

sub {

    my ( $assets ) = @_;

    $assets->load( '~/develop/assets/export.assets' );
    $assets->load( '~/develop/DOMite-js/export.assets' );

}

