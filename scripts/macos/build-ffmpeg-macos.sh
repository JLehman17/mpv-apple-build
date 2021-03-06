#!/bin/sh

# directories
FF_VERSION="4.2.1"
SOURCE="src/ffmpeg-$FF_VERSION"

DEBUG=

while getopts d option
    do
    case "${option}" in
        d) DEBUG="y"
           BUILD_DIR="build/debug"
           shift;;
    esac
done

ARCH=$1

BUILD_OUT="$BUILD_DIR/$BUILD_EXT/$ARCH/scratch/ffmpeg"
SCRATCH=$BUILD_OUT/"build"
PREFIX=$ROOT_DIR/$BUILD_OUT

PATCHES=$ROOT_DIR/patches/ffmpeg

function download_deps() {
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
        echo "FFmpeg source not found. Trying to download http://www.ffmpeg.org/releases/ffmpeg-$FF_VERSION.tar.bz2..."
        cd src
        curl http://www.ffmpeg.org/releases/ffmpeg-$FF_VERSION.tar.bz2 | tar xj || exit 1
        
        cd $ROOT_DIR/$SOURCE

        echo "Applying videotoolbox.c patches..."
        git apply $PATCHES/FFmpeg-devel-lavc-vt_hevc-fix-crash-if-vps_list-0-or-sps_list-0-are-null.patch || exit 1
        
        patch="$PATCHES/maccatalyst_videotoolbox.c.patch"
        cp $patch ./ &&
        patch -p0 < "maccatalyst_videotoolbox.c.patch" && rm "./maccatalyst_videotoolbox.c.patch" || exit 1
        
        patch="$PATCHES/maccatalyst_tls_securetransport.c.patch"
        cp $patch ./ &&
        patch -p0 < "maccatalyst_tls_securetransport.c.patch" && rm "./maccatalyst_tls_securetransport.c.patch" || exit 1

        cd $ROOT_DIR
    fi
}

CONFIGURE_FLAGS=" \
--enable-cross-compile \
--disable-ffplay \
--disable-ffprobe \
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
--disable-libaom \
--disable-sdl2 \
--disable-libzimg \
--disable-vapoursynth \
--disable-librubberband \
--disable-libbluray \
--enable-libzvbi
"


if [ "$DEBUG" ]
then
    CONFIGURE_FLAGS="$CONFIGURE_FLAGS --enable-debug --disable-stripping --disable-optimizations"
else
    CONFIGURE_FLAGS="$CONFIGURE_FLAGS --disable-debug --enable-stripping --enable-optimizations"
fi

echo $CONFIGURE_FLAGS

download_deps

CWD=`pwd`

echo "building..."
mkdir -p "$SCRATCH"
cd "$SCRATCH"

# force "configure" to use "gas-preprocessor.pl" (FFmpeg 3.3)
if [ "$ARCH" = "arm64" ]
then
    AS="gas-preprocessor.pl -arch aarch64 -- $CC"
else
    AS="gas-preprocessor.pl -- $CC"
fi

TMPDIR=${TMPDIR/%\/} $CWD/$SOURCE/configure \
    --target-os=darwin \
    --arch="${ARCH}" \
    --cc="$CC" \
    --as="$AS" \
    --sysroot="$SDKPATH" \
    $CONFIGURE_FLAGS \
    --extra-cflags="$CFLAGS" \
    --extra-ldflags="$LDFLAGS" \
    --prefix="$PREFIX" \
    --pkg-config=pkg-config \
    --libdir=$CWD/$BUILD_DIR/$BUILD_EXT/${ARCH}/lib \
    --incdir=$CWD/$BUILD_DIR/$BUILD_EXT/${ARCH}/include \
|| exit 1

# make clean
 make -j4 install || exit 1
cd $CWD

echo Done
