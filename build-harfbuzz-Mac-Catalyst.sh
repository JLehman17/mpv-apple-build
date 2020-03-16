#!/bin/sh

source config.sh

ConfigureForMacCatalyst

HARFBUZZ_VERSION="2.2.0"
SOURCE="harfbuzz-$HARFBUZZ_VERSION"
FAT="$BUILD_DIR/harfbuzz-$BUILD_EXT"
SCRATCH=$FAT/"scratch"
THIN=`pwd`/$FAT

if [ ! -r $SOURCE ]
then
    echo "harfbuzz source not found. Attempting to download..."
    curl -L "https://www.freedesktop.org/software/harfbuzz/release/$SOURCE.tar.bz2" | tar -xj || exit 1
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

#echo "Configuring with options $CONFIGURE_FLAGS"

#export CFLAGS="$CFLAGS -I$CWD/$BUILD_DIR/$BUILD_EXT/include/freetype2/"
#export CXXFLAGS="$CFLAGS"
#export CPPFLAGS="$CFLAGS"

#echo $PKG_CONFIG_LIBDIR
#echo $(pkg-config freetype2 --cflags --debug) && exit 0;
#echo $CFLAGS && exit 0;
make clean
#make distclean

$CWD/$SOURCE/configure $CONFIGURE_FLAGS \
     --prefix="$THIN" \
     --libdir=$CWD/$BUILD_DIR/$BUILD_EXT/lib \
     --includedir=$CWD/$BUILD_DIR/$BUILD_EXT/include \
 || exit 1

make -j4 install || exit 1


