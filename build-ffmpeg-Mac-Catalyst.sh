#!/bin/sh

source config.sh

ConfigureForMacCatalyst

# directories
FF_VERSION="emby"
SOURCE="ffmpeg-4.2.1"

DEBUG=
BUILD_DIR="build/release"

while getopts d option
    do
    case "${option}" in
        d) DEBUG="y"
#           BUILD_DIR="build/debug"
           shift;;
    esac
done

FAT=$BUILD_DIR/"ffmpeg-$BUILD_EXT"
SCRATCH=$FAT/"scratch"
# must be an absolute path
THIN=`pwd`/$FAT/

PATCHES=`pwd`/patches/ffmpeg


# If versions >= 4.0 See https://github.com/FFmpeg/FFmpeg/commit/b22db4f465c9adb2cf1489e04f7b65ef6bb55b8b#commitcomment-28725295
# in order to build for armv7


# absolute path to x264 library
#X264=`pwd`/fat-x264

#FDK_AAC=`pwd`/../fdk-aac-build-script-for-iOS/fdk-aac-ios

ZVBI=`pwd`/$BUILD_DIR/$BUILD_EXT

CONFIGURE_FLAGS=" \
--disable-programs \
--disable-indev=avfoundation \
--disable-doc \
--disable-symver \
--enable-pic \
--disable-shared \
--enable-static \
--enable-gpl \
--enable-videotoolbox \
--disable-decoder=dca \
--disable-decoder=mlp \
--disable-decoder=truehd \
--disable-filters \
--disable-asm \
--enabled-libaom \
"

#--disable-securetransport \

if [ "$DEBUG" ]
then
    CONFIGURE_FLAGS="$CONFIGURE_FLAGS --enable-debug --disable-stripping --disable-optimizations"
else
#    CONFIGURE_FLAGS="$CONFIGURE_FLAGS --optflags=-O"
#    --optflags="-O2"
    CONFIGURE_FLAGS="$CONFIGURE_FLAGS --disable-debug --enable-stripping --enable-optimizations"
fi

if [ "$X264" ]
then
	CONFIGURE_FLAGS="$CONFIGURE_FLAGS --enable-libx264"
fi

if [ "$X265" ]
then
    CONFIGURE_FLAGS="$CONFIGURE_FLAGS --enable-libx256"
fi

if [ "$FDK_AAC" ]
then
	CONFIGURE_FLAGS="$CONFIGURE_FLAGS --enable-libfdk-aac --enable-nonfree"
fi

if [ "$ZVBI" ]
then
    CONFIGURE_FLAGS="$CONFIGURE_FLAGS --enable-libzvbi"
fi


echo $CONFIGURE_FLAGS


COMPILE="y"
LIPO="y"

if [ "$COMPILE" ]
then
	if [ ! `which yasm` ]
	then
		echo 'Yasm not found'
		if [ ! `which brew` ]
		then
			echo 'Homebrew not found. Trying to install...'
                        ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" \
				|| exit 1
		fi
		echo 'Trying to install Yasm...'
		brew install yasm || exit 1
	fi

	if [ ! -r $SOURCE ]
	then
        echo "FFmpeg source not found. Trying to download http://www.ffmpeg.org/releases/${SOURCE}.tar.bz2..."
        curl http://www.ffmpeg.org/releases/$SOURCE.tar.bz2 | tar xj || exit 1
        
        CWD=`pwd`
        cd $SOURCE

        echo "Applying videotoolbox.c patch..."
        git apply $CWD/patches/ffmpeg/FFmpeg-devel-lavc-vt_hevc-fix-crash-if-vps_list-0-or-sps_list-0-are-null.patch || exit 1

        cd $CWD
	fi

	CWD=`pwd`

    echo "building..."
    mkdir -p "$SCRATCH"
    cd "$SCRATCH"
    
    PLATFORM="macosx"
    
    XCODE_PATH=$(xcode-select -p)
    
    export PATH="/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/:$PATH"
    export SDKPATH="$(xcodebuild -sdk $PLATFORM -version Path)"
    CFLAGS="-isysroot $SDKPATH -fembed-bitcode -target x86_64-apple-ios13.0-macabi -arch x86_64"
    LDFLAGS="-isysroot $SDKPATH -target x86_64-apple-ios13.0-macabi -arch x86_64"
    
    CXXFLAGS="$CFLAGS"
    
    XCRUN_SDK=`echo $PLATFORM | tr '[:upper:]' '[:lower:]'`
    CC="xcrun -sdk $XCRUN_SDK clang"
    
    # force "configure" to use "gas-preprocessor.pl" (FFmpeg 3.3)
    if [ "$ARCH" = "arm64" ]
    then
        AS="gas-preprocessor.pl -arch aarch64 -- $CC"
    else
        AS="gas-preprocessor.pl -- $CC"
    fi

    if [ "$X264" ]
    then
        CFLAGS="$CFLAGS -I$X264/include"
        LDFLAGS="$LDFLAGS -L$X264/lib"
    fi
    if [ "$FDK_AAC" ]
    then
        CFLAGS="$CFLAGS -I$FDK_AAC/include"
        LDFLAGS="$LDFLAGS -L$FDK_AAC/lib"
    fi
    if [ "$ZVBI" ]
    then
        CFLAGS="$CFLAGS -I$ZVBI/include"
        LDFLAGS="$LDFLAGS -L$ZVBI/lib"
    fi

    export PKG_CONFIG_SYSROOT_DIR="$CWD/$BUILD_DIR/$BUILD_EXT"
    export PKG_CONFIG_LIBDIR="$PKG_CONFIG_SYSROOT_DIR/lib/pkgconfig"
    
    TMPDIR=${TMPDIR/%\/} $CWD/$SOURCE/configure \
        --target-os=darwin \
        --arch="x86_64" \
        --cc="$CC" \
        --as="$AS" \
        $CONFIGURE_FLAGS \
        --extra-cflags="$CFLAGS" \
        --extra-ldflags="$LDFLAGS" \
        --prefix="$THIN" \
        --pkg-config=pkg-config \
        --libdir=$CWD/$BUILD_DIR/$BUILD_EXT/lib \
        --incdir=$CWD/$BUILD_DIR/$BUILD_EXT/include \
    || exit 1

     make clean
     make -j4 install || exit 1
    cd $CWD
fi

echo Done
