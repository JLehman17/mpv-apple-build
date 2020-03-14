#!/bin/sh


ARCHS="arm64 x86_64"
DEPLOYMENT_TARGET="9.0.0"

LIPO="y"
COMPILE="y"

CWD=`pwd`
MPV_VERSION="master"
SOURCE="mpv-$MPV_VERSION"

DEBUG=
BUILD_DIR="build/release/mpv-iOS"
while getopts d option
do
    case "${option}" in
        d) DEBUG="y"
           BUILD_DIR="build/mpv-iOS/debug"
           shift;;
    esac
done

THIN=$CWD/$BUILD_DIR/"thin"
SCRATCH=$CWD/$BUILD_DIR/"scratch"
FFMPEG_BUILD=$BUILD_DIR/"ffmpeg-iOS"

CONFIGURE_FLAGS=" \
--disable-cplayer \
--disable-lcms2 \
--disable-lua \
--disable-javascript \
--disable-swift \
--disable-cuda-hwaccel \
--enable-libmpv-static \
--enable-ios-gl \
--disable-uchardet \
--enable-gl \
--enable-lgpl \
"

if [ "$DEBUG" ]
then
    CONFIGURE_FLAGS="$CONFIGURE_FLAGS --disable-optimize --enable-debug-build"
else
    CONFIGURE_FLAGS="$CONFIGURE_FLAGS --disable-debug-build"
fi


if [ "$*" ]
then
    if [ "$*" = "lipo" ]
    then
        # skip compile
        COMPILE=
    else
        ARCHS="$*"
        if [ $# -eq 1 ]
        then
            # skip lipo
            LIPO=
        fi
    fi
fi

if [ "$COMPILE" ]
then
    if [ ! -r $SOURCE ]
    then
        echo 'mpv source not found. Trying to download...'

        if [ "$MPV_VERSION" = "master" ]
        then
            curl -L https://github.com/mpv-player/mpv/archive/"$MPV_VERSION".tar.gz | tar xj || exit 1
        else
            curl -L https://github.com/mpv-player/mpv/archive/v"$MPV_VERSION".tar.gz | tar xj || exit 1
        fi

        PATCHES=`pwd`/patches
        cd ./"$SOURCE"/
        ./bootstrap.py

        # Apply patches
#        echo "Applying ao_audiounit.m patch..."
#        mv $PATCHES/ao_audiounit.m.patch ./ &&
#        patch -p0 < ./ao_audiounit.m.patch &&
#        mv ./ao_audiounit.m.patch $PATCHES

#        echo "Applying gl_headers.h patch..."
#        mv $PATCHES/gl_headers.h.patch ./ &&
#        patch -p0 < ./gl_headers.h.patch &&
#        mv ./gl_headers.h.patch $PATCHES

    else
          cd ./"$SOURCE"/
    fi


    #./waf clean
    #./waf distclean

    for ARCH in $ARCHS
    do

        echo "Building $ARCH..."

        if [ "$ARCH" = "i386" -o "$ARCH" = "x86_64" ]
        then
            PLATFORM="iphonesimulator"
        else
            PLATFORM="iphoneos"
        fi

        export PATH="/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/:$PATH"
        export SDKPATH="$(xcodebuild -sdk $PLATFORM -version Path)"
        export CFLAGS="-isysroot $SDKPATH -arch $ARCH -mios-version-min=$DEPLOYMENT_TARGET -fembed-bitcode \
                        -I$CWD/$FFMPEG_BUILD/thin/$ARCH/include"
        export LDFLAGS="-isysroot $SDKPATH -arch $ARCH -Wl,-ios_version_min,$DEPLOYMENT_TARGET -lbz2 \
                        -L$CWD/$FFMPEG_BUILD/thin/$ARCH/lib"


    #--enable-videotoolbox-gl
        OPTION_FLAGS=" $CONFIGURE_FLAGS \
--out=$SCRATCH/$ARCH \
--includedir=$THIN/$ARCH/include \
--prefix=$THIN/$ARCH
"

        echo "Configuring with options $OPTION_FLAGS"
#echo $LDFLAGS
#echo $CFLAGS
#exit 0

        ./waf configure $OPTION_FLAGS || exit 1
        ./waf build -j4 || exit 1
        ./waf install || exit 1

    done

    cd ./..
fi

if [ "$LIPO" ]
then
    echo "building fat binaries..."
    set - $ARCHS
    CWD=`pwd`
    mkdir -p $CWD/$BUILD_DIR/lib
    cd $THIN/$1/lib
    for LIB in *.a
    do
        cd $CWD
        echo lipo -create `find $THIN -name $LIB` -output $CWD/$BUILD_DIR/lib/$LIB 1>&2
        lipo -create `find $THIN -name $LIB` -output $CWD/$BUILD_DIR/lib/$LIB || exit 1
    done

    cd $CWD
    cp -rf $THIN/$1/include $CWD/$BUILD_DIR
fi


echo Done


