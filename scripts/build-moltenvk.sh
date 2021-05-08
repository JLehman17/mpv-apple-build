#!/bin/sh

ARCH=$1

VERSION="1.1.2"
SOURCE="src/moltenVK-$VERSION-$BUILD_EXT"

BUILD_OUT="$BUILD_DIR/$BUILD_EXT/$ARCH/scratch/mpv"
SCRATCH=$BUILD_OUT/"build"
PREFIX=$ROOT_DIR/$BUILD_OUT

echo "This script doesn't work. Don't know why. Run the commands on the command line instead."

if [ ! -r $SOURCE ]
then
    echo 'MoltenVK source not found. Trying to download...'

    mkdir -p $SOURCE && curl -L "https://github.com/KhronosGroup/MoltenVK/archive/v${VERSION}.tar.gz" |
        tar xj -C $SOURCE --strip-components 1 || exit 1
        
    cd $ROOT_DIR/$SOURCE
    ./fetchDependencies --maccat
fi

cd $ROOT_DIR/$SOURCE
make maccat || exit 1

echo Done
