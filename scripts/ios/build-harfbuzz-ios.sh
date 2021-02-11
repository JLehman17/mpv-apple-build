#!/bin/sh

ARCH=$1

HARFBUZZ_VERSION="2.7.2"
SOURCE="src/harfbuzz-$HARFBUZZ_VERSION"
SCRATCH="$BUILD_DIR/$BUILD_EXT/$ARCH/scratch/harfbuzz"
BUILD_OUT=$SCRATCH/"build"
PREFIX=`pwd`/$BUILD_OUT

root=$(pwd)

if [ ! -r $SOURCE ]
then
    echo "harfbuzz source not found. Attempting to download..."
    cd src
    wget https://github.com/harfbuzz/harfbuzz/releases/download/$HARFBUZZ_VERSION/harfbuzz-$HARFBUZZ_VERSION.tar.xz -O - | \
        tar -xJ
    cd $root
fi

CWD=`pwd`
echo "building... $ARCH"
mkdir -p "$BUILD_OUT"
cd "$BUILD_OUT"

config_guess=$root/$SOURCE/config.guess
host=$($config_guess)

CONFIGURE_FLAGS=" \
--disable-shared \
--enable-static \
--disable-gtk-doc-html \
--with-cairo=no \
--with-freetype=yes \
--with-icu=no \
--with-glib=no \
--with-fontconfig=no \
--host=${host} \
"

export LDFLAGS="$LDFLAGS -lz"

$CWD/$SOURCE/configure $CONFIGURE_FLAGS \
     --prefix="$PREFIX" \
     --libdir=$CWD/$BUILD_DIR/$BUILD_EXT/$ARCH/lib \
     --includedir=$CWD/$BUILD_DIR/$BUILD_EXT/$ARCH/include \
 || exit 1

make -j4 install || exit 1


