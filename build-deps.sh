#!/bin/sh

set -e

source config.sh

ConfigureForMacCatalyst
#ConfigureForMacOS

#./build-zvbi-Mac-Catalyst.sh
#./build-freetype-Mac-Catalyst.sh
#./build-fribidi-Mac-Catalyst.sh
#./build-harfbuzz-Mac-Catalyst.sh
#./build-libass-Mac-Catalyst.sh
#./build-ffmpeg-Mac-Catalyst.sh
./build-mpv-Mac-Catalyst.sh
