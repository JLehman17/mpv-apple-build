#!/bin/sh

ARCH=$1

#if [ "$BUILD_EXT" == "watchos" ]
#then
#    # 0.33.0 doesn't use posix-spawn which is prohibited on watchOS... Unfortuantely it also make libass a requirement.
#    MPV_VERSION="0.33.0"
#else
#    MPV_VERSION="0.32.0"
#fi
MPV_VERSION="0.32.0"
SOURCE="src/mpv-$MPV_VERSION-$BUILD_EXT"

BUILD_OUT="$BUILD_DIR/$BUILD_EXT/$ARCH/scratch/mpv"
SCRATCH=$BUILD_OUT/"build"
PREFIX=$ROOT_DIR/$BUILD_OUT

DEBUG="-d"
while getopts d option
do
    case "${option}" in
        d) DEBUG="y"
#           BUILD_DIR="build/debug"
           shift;;
    esac
done

if [ ! -r $SOURCE ]
then
    echo 'mpv source not found. Trying to download...'

#    cd src
    if [ "$MPV_VERSION" = "master" ]
    then
        mpv_name="$MPV_VERSION"
    else
        mpv_name="v$MPV_VERSION"
    fi
    mkdir -p $SOURCE && curl -L https://github.com/mpv-player/mpv/archive/"$mpv_name".tar.gz |
        tar xj -C $SOURCE --strip-components 1 || exit 1

    cd $ROOT_DIR/$SOURCE
    ./bootstrap.py
    cd $ROOT_DIR
fi

CONFIGURE_FLAGS=" \
--disable-cplayer \
--disable-lcms2 \
--disable-lua \
--disable-javascript \
--disable-cuda-hwaccel \
--enable-libmpv-static \
--disable-uchardet \
--enable-gl \
--enable-lgpl \
--disable-rubberband \
--disable-libbluray \
--disable-zimg \
--disable-vapoursynth
"

if [ "$DEBUG" ]
then
    CONFIGURE_FLAGS="$CONFIGURE_FLAGS --disable-optimize"
else
    CONFIGURE_FLAGS="$CONFIGURE_FLAGS"
fi

if [ "$BUILD_EXT" == "watchos" ]
then
    CONFIGURE_FLAGS="$CONFIGURE_FLAGS --disable-libass"
fi

CWD=`pwd`
echo "building..."
mkdir -p "$PREFIX"
cd "$SOURCE"

export CFLAGS="$CFLAGS -fembed-bitcode"
export LDFLAGS="$LDFLAGS -lbz2 -framework CoreAudio"

echo "Configuring with options $CONFIGURE_FLAGS"

./waf clean
./waf configure $CONFIGURE_FLAGS \
    --prefix="$PREFIX" \
    --out="$PREFIX" \
    --libdir="$CWD/$BUILD_DIR/$BUILD_EXT/$ARCH/lib" \
    --includedir="$CWD/$BUILD_DIR/$BUILD_EXT/$ARCH/include" \
|| exit 1
./waf build -j6 || exit 1
./waf install || exit 1

echo Done
