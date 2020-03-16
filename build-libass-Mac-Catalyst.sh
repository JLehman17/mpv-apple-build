#!/bin/sh

source config.sh

ConfigureForMacCatalyst

LIBASS_VERSION="0.14.0"
SOURCE="libass-$LIBASS_VERSION"
FAT="$BUILD_DIR/libass-$BUILD_EXT"
SCRATCH=$FAT/"scratch"
THIN=`pwd`/$FAT

if [ ! -r $SOURCE ]
then
    echo "libass source not found. Attempting to download..."
    curl -L "https://github.com/libass/libass/releases/download/$LIBASS_VERSION/libass-$LIBASS_VERSION.tar.gz" | tar -xj || exit 1
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
