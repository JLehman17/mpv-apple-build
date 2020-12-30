#!/bin/sh

ARCH=$1

MPV_VERSION="0.32.0"
SOURCE="src/mpv-$MPV_VERSION"

BUILD_OUT="$BUILD_DIR/$BUILD_EXT/$ARCH/scratch/mpv"
SCRATCH=$BUILD_OUT/"build"
PREFIX=$ROOT_DIR/$BUILD_OUT

DEBUG=
while getopts d option
do
    case "${option}" in
        d) DEBUG="y"
           BUILD_DIR="build/debug"
           shift;;
    esac
done

if [ ! -r $SOURCE ]
then
    echo 'mpv source not found. Trying to download...'

    cd src
    if [ "$MPV_VERSION" = "master" ]
    then
        curl -L https://github.com/mpv-player/mpv/archive/"$MPV_VERSION".tar.gz | tar xj || exit 1
    else
        curl -L https://github.com/mpv-player/mpv/archive/v"$MPV_VERSION".tar.gz | tar xj || exit 1
    fi

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
--disable-zimg \
--disable-vapoursynth \
--disable-rubberband \
--disable-libbluray \
--enable-gl \
--enable-lgpl \
"

if [ "$DEBUG" ]
then
    CONFIGURE_FLAGS="$CONFIGURE_FLAGS --disable-optimize"
else
    CONFIGURE_FLAGS="$CONFIGURE_FLAGS --disable-optimize --disable-debug-build"
fi

CWD=`pwd`
echo "building..."
mkdir -p "$PREFIX"
cd "$SOURCE"

export CFLAGS="$CFLAGS -fembed-bitcode"
export LDFLAGS="$LDFLAGS -lbz2"

echo "Configuring with options $CONFIGURE_FLAGS"

./waf clean
./waf configure $CONFIGURE_FLAGS \
    --prefix="$PREFIX" \
    --out="$PREFIX" \
    --libdir="$CWD/$BUILD_DIR/$BUILD_EXT/$ARCH/lib" \
    --includedir="$CWD/$BUILD_DIR/$BUILD_EXT/$ARCH/include" \
|| exit 1
./waf build -j4 || exit 1
./waf install || exit 1

echo Done
