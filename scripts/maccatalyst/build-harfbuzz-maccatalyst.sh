#!/bin/sh

#source config.sh
#
#ConfigureForMacCatalyst

HARFBUZZ_VERSION="2.2.0"
SOURCE="src/harfbuzz-$HARFBUZZ_VERSION"
FAT="$BUILD_DIR/harfbuzz-$BUILD_EXT"
SCRATCH=$FAT/"scratch"
THIN=`pwd`/$FAT
ARCH=$1

root=$(pwd)

if [ ! -r $SOURCE ]
then
    echo "harfbuzz source not found. Attempting to download..."
    cd src
    curl -L "https://www.freedesktop.org/software/harfbuzz/release/harfbuzz-$HARFBUZZ_VERSION.tar.bz2" | tar -xj || exit 1
    cd $root
fi

CWD=`pwd`
echo "building..."
mkdir -p "$SCRATCH"
cd "$SCRATCH"

CONFIGURE_FLAGS=" \
--disable-shared \
--enable-static \
--disable-gtk-doc-html \
--with-cairo=no \
--with-freetype=yes \
--with-icu=no \
--with-glib=no \
--with-fontconfig=no \
"

$CWD/$SOURCE/configure $CONFIGURE_FLAGS \
     --prefix="$THIN" \
     --libdir=$CWD/$BUILD_DIR/$BUILD_EXT/$ARCH/lib \
     --includedir=$CWD/$BUILD_DIR/$BUILD_EXT/$ARCH/include \
 || exit 1

make -j4 install || exit 1


