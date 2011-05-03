package App::assetize::Assets;

use strict;
use warnings;

use Try::Tiny;
use App::assetize::Assets::Manifest;

use Any::Moose;

has manifest => qw/ is ro lazy_build 1 /;
sub _build_manifest {
    return App::assetize::Assets::Manifest->new;
}

1;
