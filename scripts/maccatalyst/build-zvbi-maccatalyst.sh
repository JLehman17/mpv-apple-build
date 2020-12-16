#!/bin/sh

#source config.sh
#
#ConfigureForMacCatalyst

    # directories
ZVBI_VERSION="0.2.35"
SOURCE="src/zvbi-$ZVBI_VERSION"
FAT="$BUILD_DIR/zvbi-$BUILD_EXT"
SCRATCH=$FAT/"scratch"
# must be an absolute path
THIN=`pwd`/$FAT


CONFIGURE_FLAGS=" \
--disable-shared \
--disable-rpath \
--without-doxygen \
"
#--enable-cross-compile \
#--disable-debug \
#--disable-programs \
#--disable-doc \
#--disable-symver \
#--enable-pic \
#--disable-shared \
#--enable-static \
#--enable-gpl \
#"

echo $CONFIGURE_FLAGS

COMPILE="y"
ARCH=$1

root=$(pwd)

if [ "$COMPILE" ]
then

	if [ ! -r $SOURCE ]
	then
		echo 'zvbi source not found. Trying to download...'
        cd src
        curl -L https://sourceforge.net/projects/zapping/files/zvbi/"$ZVBI_VERSION"/zvbi-"$ZVBI_VERSION".tar.bz2/download | tar xj || exit 1
        
        CWD=`pwd`
        
        cd $SOURCE
        echo "Applying patches..."
        PATCH="$root/patches/zvbi/Makefile.in.patch"
        cp $PATCH ./ &&
        patch -p0 < "Makefile.in.patch" && rm "./Makefile.in.patch" || exit 1
        cd $root
	fi

	CWD=`pwd`
    echo "building..."
    mkdir -p "$SCRATCH"
    cd "$SCRATCH"

    TMPDIR=${TMPDIR/%\/} $CWD/$SOURCE/configure \
        $CONFIGURE_FLAGS \
        --prefix="$THIN" \
        --libdir="$CWD/$BUILD_DIR/$BUILD_EXT/$ARCH/lib" \
        --includedir="$CWD/$BUILD_DIR/$BUILD_EXT/$ARCH/include" \
    || exit 1


     make -j4 install || exit 1
    cd $CWD
fi

echo Done
