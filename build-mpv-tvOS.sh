#!/bin/sh


ARCHS="arm64 x86_64"
DEPLOYMENT_TARGET="9.0.0"

LIPO="y"
COMPILE="y"

CWD=`pwd`
MPV_VERSION="master"
SOURCE="mpv"

DEBUG=
BUILD_DIR="build/release/mpv-tvOS"
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
FFMPEG_BUILD=$BUILD_DIR/"ffmpeg-tvOS"

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

        cd ./"$SOURCE"/
        ./bootstrap.py

    else
        cd ./"$SOURCE"/
    fi

    # Apply patches

#    PATCHES=$CWD/patches

#        echo "Applying ao_audiounit.m patch..."
#        mv $PATCHES/ao_audiounit.m.patch ./ &&
#        patch -p0 < ./ao_audiounit.m.patch &&
#        mv ./ao_audiounit.m.patch $PATCHES

#        echo "Applying gl_headers.h patch..."
#        mv $PATCHES/gl_headers.h.patch ./ &&
#        patch -p0 < ./gl_headers.h.patch &&
#        mv ./gl_headers.h.patch $PATCHES

    # Needed because fork() isn't available on tvOS.
#    echo "Applying wscript patch..."
#    cp $PATCHES/wscript.patch ./ &&
#    patch -p0 < ./wscript.patch &&
#    rm ./wscript.patch

    #./waf clean
    #./waf distclean

    for ARCH in $ARCHS
    do

        echo "Building $ARCH..."

        if [ "$ARCH" = "i386" -o "$ARCH" = "x86_64" ]
        then
            PLATFORM="appletvsimulator"
        else
            PLATFORM="appletvos"
        fi

        export PATH="/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/:$PATH"
        export SDKPATH="$(xcodebuild -sdk $PLATFORM -version Path)"
        export CFLAGS="-isysroot $SDKPATH -arch $ARCH -mtvos-version-min=$DEPLOYMENT_TARGET -fembed-bitcode \
                        -I$CWD/build/release/libs-tvOS/thin/${ARCH}/include"
        export LDFLAGS="-isysroot $SDKPATH -arch $ARCH -mtvos-version-min=$DEPLOYMENT_TARGET -lbz2 \
                        -L$CWD/build/release/libs-tvOS/thin/${ARCH}/lib"
                        
        export PKG_CONFIG_SYSROOT_DIR="$CWD/build/release/libs-tvOS/thin"
        export PKG_CONFIG_LIBDIR="$PKG_CONFIG_SYSROOT_DIR/$ARCH/lib/pkgconfig"


    #--enable-videotoolbox-gl
        OPTION_FLAGS=" \
        --disable-cplayer \
        --disable-lcms2 \
        --disable-lua \
        --disable-javascript \
        --disable-swift \
        --disable-cuda-hwaccel \
        --disable-uchardet \
        --enable-libmpv-static \
        --enable-ios-gl \
        --enable-gl \
        --enable-lgpl \
        --out=$SCRATCH/$ARCH \
        --includedir=$THIN/$ARCH/include \
        --prefix=$THIN/$ARCH
        "

        if [ "$DEBUG" ]
        then
            OPTION_FLAGS="$OPTION_FLAGS --disable-optimize --enable-debug-build"
        else
            OPTION_FLAGS="$OPTION_FLAGS --disable-debug-build"
        fi

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


