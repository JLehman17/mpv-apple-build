#!/bin/sh

#    If you checked out the sources from CVS, run "./autogen.sh" to create
#    missing configuration and make files.
#
#    To build and install type "./configure", "make", "make check" if you
#    want to run some tests, and "make install".

    # directories
ZVBI_VERSION="0.2.35"
SOURCE="zvbi-$ZVBI_VERSION"
BUILD_DIR="build/release"
FAT="$BUILD_DIR/zvbi-macOS"
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

if [ "$COMPILE" ]
then

	if [ ! -r $SOURCE ]
	then
		echo 'zvbi source not found. Trying to download...'
        curl -L https://sourceforge.net/projects/zapping/files/zvbi/"$ZVBI_VERSION"/zvbi-"$ZVBI_VERSION".tar.bz2/download | tar xj || exit 1
        
        CWD=`pwd`
        
        cd $SOURCE
        echo "Applying patches..."
        PATCH="$CWD/patches/zvbi/Makefile.in.patch"
        cp $PATCH ./ &&
        patch -p0 < "Makefile.in.patch" && rm "./Makefile.in.patch" || exit 1
        cd ..
	fi

	CWD=`pwd`
    echo "building..."
    mkdir -p "$SCRATCH"
    cd "$SCRATCH"
    
    PLATFORM="macosx"

    export PATH="/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/:$PATH"
    export SDKPATH="$(xcodebuild -sdk $PLATFORM -version Path)"
    export CFLAGS="-isysroot $SDKPATH -fembed-bitcode -target x86_64-apple-ios13.0-macabi"
    export LDFLAGS="-isysroot $SDKPATH -Wl "

    export CXXFLAGS="$CFLAGS"

    TMPDIR=${TMPDIR/%\/} $CWD/$SOURCE/configure \
        $CONFIGURE_FLAGS \
        --prefix="$THIN" \
        --libdir=$CWD/$BUILD_DIR/macOS/lib \
        --includedir=$CWD/$BUILD_DIR/macOS/include \
    || exit 1


     make -j4 install || exit 1
    cd $CWD
fi

echo Done
