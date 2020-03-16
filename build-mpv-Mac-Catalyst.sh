#!/bin/sh

source config.sh

ConfigureForMacCatalyst

MPV_VERSION="master"
SOURCE="mpv-$MPV_VERSION"
FAT="$BUILD_DIR/mpv-$BUILD_EXT"
SCRATCH=$FAT/"scratch"
THIN=`pwd`/$FAT

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

    if [ "$MPV_VERSION" = "master" ]
    then
        curl -L https://github.com/mpv-player/mpv/archive/"$MPV_VERSION".tar.gz | tar xj || exit 1
    else
        curl -L https://github.com/mpv-player/mpv/archive/v"$MPV_VERSION".tar.gz | tar xj || exit 1
    fi

    ./$SOURCE/bootstrap.py
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
"

if [ "$DEBUG" ]
then
    CONFIGURE_FLAGS="$CONFIGURE_FLAGS --disable-optimize --enable-debug-build"
else
    CONFIGURE_FLAGS="$CONFIGURE_FLAGS --disable-debug-build"
fi


#./waf clean
#./waf distclean

CWD=`pwd`
echo "building..."
mkdir -p "$SCRATCH"
cd "$SOURCE"

export CFLAGS="$CFLAGS -fembed-bitcode"
export LDFLAGS="$LDFLAGS -lbz2"


#--enable-videotoolbox-gl
#OPTION_FLAGS=" $CONFIGURE_FLAGS \
#--out=$SCRATCH/$ARCH \
#--includedir=$THIN/$ARCH/include \
#--prefix=$THIN/$ARCH
#"

echo "Configuring with options $CONFIGURE_FLAGS"

./waf configure $CONFIGURE_FLAGS \
    --prefix="$THIN" \
    --out="$THIN" \
    --libdir=$CWD/$BUILD_DIR/$BUILD_EXT/lib \
    --includedir=$CWD/$BUILD_DIR/$BUILD_EXT/include \
|| exit 1
./waf build -j4 || exit 1
./waf install || exit 1

echo Done
