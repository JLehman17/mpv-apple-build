#!/bin/sh

#source config.sh
#
#ConfigureForMacCatalyst

FRIBIDI_VERSION="1.0.9"
SOURCE="fribidi-$FRIBIDI_VERSION"
FAT="$BUILD_DIR/fribidi-$BUILD_EXT"
SCRATCH=$FAT/"scratch"
THIN=`pwd`/$FAT

if [ ! -r $SOURCE ]
then
    echo "harfbuzz source not found. Attempting to download..."
    curl -L "https://github.com/fribidi/fribidi/releases/download/v$FRIBIDI_VERSION/$SOURCE.tar.xz" | tar -xj || exit 1
fi

CWD=`pwd`
echo "building..."
mkdir -p "$SCRATCH"
cd "$SCRATCH"

CONFIGURE_FLAGS=" \
--disable-shared \
--enable-static \
"

echo "Configuring with options $CONFIGURE_FLAGS"

#make clean
#make distclean

$CWD/$SOURCE/configure $CONFIGURE_FLAGS \
     --prefix="$THIN" \
     --libdir=$CWD/$BUILD_DIR/$BUILD_EXT/lib \
     --includedir=$CWD/$BUILD_DIR/$BUILD_EXT/include \
 || exit 1

make -j4 install || exit 1

echo Done
