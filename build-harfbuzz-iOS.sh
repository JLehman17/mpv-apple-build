#!/bin/sh -e

source config.sh

HARFBUZZ_VERSION="2.7.2"
SOURCE="harfbuzz-$HARFBUZZ_VERSION"
BUILD="Harfbuzz-iOS"
THIN=`pwd`/$BUILD/"thin"

ARCHS="arm64"

COMPILE="y"
LIPO="y"

DEPLOYMENT_TARGET="9.0"

if [ "$*" ]
then
    if [ "$*" = "lipo" ]
    then
        # skip compile
        COMPILE=
    else
        ARCHS="$*"
        if [ $# -eq 1 ]
        then
            # skip lipo
            LIPO=
        fi
    fi
fi

if [ "$COMPILE" ]
then

    if [ ! -r $SOURCE ]
    then
        echo "harfbuzz source not found. Attempting to download..."
        wget https://github.com/harfbuzz/harfbuzz/releases/download/$HARFBUZZ_VERSION/harfbuzz-$HARFBUZZ_VERSION.tar.xz -O - | \
            tar -xJ
    fi

    cd ./$SOURCE
    
    export LDFLAGS="$LDFLAGS -lz -lbz2"

    for ARCH in $ARCHS
    do

        echo "building $ARCH..."

        config_for_ios $ARCH
        
        CONFIGURE_FLAGS=" \
        --disable-shared \
        --enable-static \
        --disable-gtk-doc-html \
        --with-cairo=no \
        --with-freetype=yes \
        --with-icu=no \
        --with-glib=no \
        --with-fontconfig=no \
        --host=arm-apple-darwin \
        --with-sysroot=$SDKPATH \
        --prefix=$THIN/$ARCH
        "

#CONFIGURE_FLAGS=" \
#--disable-shared \
#--enable-static \
#--disable-gtk-doc-html \
#--with-cairo=no \
#--with-freetype=yes \
#--host=aarch64-apple-darwin \
#--with-sysroot=$SDKPATH \
#--prefix=$THIN/$ARCH
#"

        echo "Configuring with options $CONFIGURE_FLAGS"

#        ./autogen.sh

        ./configure $CONFIGURE_FLAGS &&
        make -j8 install || exit 1

    done

    cd ..

fi
