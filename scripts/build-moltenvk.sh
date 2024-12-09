#!/bin/sh

ARCH=$1

VERSION="1.2.8"
SOURCE="src/moltenVK-$VERSION-$BUILD_EXT"

BUILD_OUT="${ROOT_DIR}/${BUILD_DIR}/${BUILD_EXT}/${ARCH}/scratch/moltenVK"
PREFIX="${ROOT_DIR}/${BUILD_DIR}/${BUILD_EXT}/${ARCH}"

echo "This script doesn't work. Don't know why. Run the commands on the command line instead."

platform="$BUILD_EXT"
if [ "$BUILD_EXT" == "tvos" ]
then
    platform="tvos"
elif [ "$BUILD_EXT" == "maccatalyst" ]
then
    platform="maccat"
fi

if [ ! -r $SOURCE ]
then
    echo 'MoltenVK source not found. Trying to download...'

    mkdir -p $SOURCE && curl -L "https://github.com/KhronosGroup/MoltenVK/archive/v${VERSION}.tar.gz" |
        tar xj -C $SOURCE --strip-components 1 || exit 1
        
    cd $ROOT_DIR/$SOURCE
    ./fetchDependencies "--${platform}"
fi

cd $ROOT_DIR/$SOURCE
make "${platform}" || exit 1

echo Done
