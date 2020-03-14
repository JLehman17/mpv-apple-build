#!/bin/sh


ARCHS="armv7 i386"
DEPLOYMENT_TARGET="9.0.0"

LIPO="y"
COMPILE="y"

CWD=`pwd`
BUILD_DIR="mpv-watchOS"
MPV_VERSION="0.29.1"
SOURCE="mpv"
#SOURCE="mpv-$MPV_VERSION"
FAT="fat"
THIN=$CWD/$BUILD_DIR/"thin"
SCRATCH=$CWD/$BUILD_DIR/"scratch"

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
        PATCHES=`pwd`/patches
        curl -L https://github.com/mpv-player/mpv/archive/v"$MPV_VERSION".tar.gz | tar xj || exit 1
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
            PLATFORM="watchsimulator"
        else
            PLATFORM="watchos"
        fi

        export PATH="/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/:$PATH"
        export SDKPATH="$(xcodebuild -sdk $PLATFORM -version Path)"
        export CFLAGS="-isysroot $SDKPATH -arch $ARCH -fembed-bitcode \
    -I$CWD/FFmpeg-iOS/thin/$ARCH/include"
        export LDFLAGS="-isysroot $SDKPATH -arch $ARCH -Wl, -lbz2 \
    -L$CWD/FFmpeg-iOS/thin/$ARCH/lib"


    #--enable-videotoolbox-gl
        OPTION_FLAGS=" \
        --disable-libass \
        --disable-libass-osd \
        --disable-cplayer \
        --disable-lcms2 \
        --disable-lua \
        --disable-javascript \
        --disable-swift \
        --disable-cuda-hwaccel \
        --enable-libmpv-static \
        --disable-uchardet \
        --enable-gl \
        --enable-lgpl \
        --out=$SCRATCH/$ARCH \
        --includedir=$THIN/$ARCH/include \
        --prefix=$THIN/$ARCH
        "


        echo "Configuring with options $OPTION_FLAGS"

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
    CWD=`pwd`/$BUILD_DIR
    mkdir -p $CWD/$FAT/lib
    cd $THIN/$1/lib
    for LIB in *.a
    do
        cd $CWD
        echo lipo -create `find $THIN -name $LIB` -output $CWD/$FAT/lib/$LIB 1>&2
        lipo -create `find $THIN -name $LIB` -output $CWD/$FAT/lib/$LIB || exit 1
    done

    cd $CWD
    cp -rf $THIN/$1/include $CWD/$FAT
fi


echo Done


