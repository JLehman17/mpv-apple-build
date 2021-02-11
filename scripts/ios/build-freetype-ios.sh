#!/bin/sh

#source config.sh
#
#ConfigureForMacCatalyst

CWD=`pwd`

FREETYPE_VERSION="2.10.1"
SOURCE="freetype-$FREETYPE_VERSION"
BUILD="$CWD/$BUILD_DIR"
SCRATCH="$BUILD/freetype-$BUILD_EXT"

if [ ! -r $SOURCE ]
then
    echo "freetype source not found. Attempting to download..."
    curl -L "https://download.savannah.gnu.org/releases/freetype/$SOURCE.tar.xz" | tar -xj || exit 1
fi

echo "building..."
mkdir -p "$SCRATCH"
cd "$SCRATCH"

CONFIGURE_FLAGS=" \
--disable-shared \
--enable-static \
--disable-freetype-config \
--with-harfbuzz=no \
"

echo "Configuring with options $CONFIGURE_FLAGS"

config_guess=$ROOT_DIR/$SOURCE/builds/unix/config.guess
host=$($config_guess)

$CWD/$SOURCE/configure $CONFIGURE_FLAGS \
     --host="$host"
     --prefix="$SCRATCH" \
     --libdir="$CWD/$BUILD_DIR/$BUILD_EXT/lib" \
     --includedir="$CWD/$BUILD_DIR/$BUILD_EXT/include" \
 || exit 1

make -j4 install || exit 1


