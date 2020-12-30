#!/bin/sh

ARCH=$1

CWD=`pwd`

FREETYPE_VERSION="2.10.1"
SOURCE="src/freetype-$FREETYPE_VERSION"
BUILD_OUT="$BUILD_DIR/$BUILD_EXT/$ARCH/scratch/freetype"
SCRATCH=$BUILD_OUT/"build"
PREFIX=$ROOT_DIR/$BUILD_OUT

root=$(pwd)

if [ ! -r $SOURCE ]
then
    echo "freetype source not found. Attempting to download..."
    cd src
    curl -L "https://download.savannah.gnu.org/releases/freetype/freetype-$FREETYPE_VERSION.tar.xz" | tar -xj || exit 1
    cd $root
fi

echo "building..."
mkdir -p "$SCRATCH"
cd "$SCRATCH"

config_guess=$root/$SOURCE/builds/unix/config.guess
host=$($config_guess)

CONFIGURE_FLAGS=" \
--disable-shared \
--enable-static \
--disable-freetype-config \
--with-harfbuzz=no \
--with-png=no \
--host=${host} \
"

echo "Configuring with options $CONFIGURE_FLAGS"

#make clean
#make distclean

$CWD/$SOURCE/configure $CONFIGURE_FLAGS \
     --prefix="$PREFIX" \
     --libdir="$CWD/$BUILD_DIR/$BUILD_EXT/$ARCH/lib" \
     --includedir="$CWD/$BUILD_DIR/$BUILD_EXT/$ARCH/include" \
 || exit 1

make -j4 install || exit 1


