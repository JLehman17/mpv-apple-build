#!/bin/sh

# directories
FF_VERSION="4.2.1"
# watchos version is FF_VERSION="4.2.1-watchos"
# maccatlyst version is FF_VERSION="4.2.1"
SOURCE="src/ffmpeg-$FF_VERSION"

DEBUG=
enable_all_decoders="y"

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

CWD=`pwd`

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
        
        if [ "$BUILD_EXT" == "watchos" ]
        then
            patch="$PATCHES/watchos_configure.patch"
            cp $patch ./ &&
            patch -p0 < "watchos_configure.patch" && rm "./watchos_configure.patch" || exit 1
        fi

        cd $ROOT_DIR
    fi
}

CONFIGURE_FLAGS=" \
--enable-cross-compile \
--disable-ffplay \
--disable-ffprobe \
--disable-programs \
--disable-postproc \
--disable-indev=avfoundation \
--disable-indev=libndi_newtek \
--disable-outdev=libndi_newtek \
--disable-doc \
--disable-symver \
--enable-pic \
--disable-shared \
--enable-static \
--enable-gpl \
--enable-nonfree \
--disable-filters \
--disable-librubberband \
--disable-libzimg \
--disable-libbluray \
--disable-vapoursynth \
"

openssl="${CWD}/${BUILD_DIR}/${BUILD_EXT}/${ARCH}/lib/libssl.a"
if [ -f $openssl ]
then
    echo "Configuring with OpenSSL instead of SecureTransport."
    CONFIGURE_FLAGS="$CONFIGURE_FLAGS \
--enable-openssl \
--disable-securetransport"
else
    echo "Could not find an OpenSSL Build at ${openssl}"
fi

if [ ! "$enable_all_decoders" ]
then
    CONFIGURE_FLAGS="$CONFIGURE_FLAGS \
--disable-decoder=dca \
--disable-decoder=mlp \
--disable-decoder=truehd"
fi

if [ "$BUILD_EXT" == "ios" -o "$BUILD_EXT" == "maccatalyst" ]
then
    # audiotoolbox.m currently doesn't compile for iOS.
    CONFIGURE_FLAGS="$CONFIGURE_FLAGS \
--disable-outdev=audiotoolbox \
--disable-libxcb \
--disable-libxcb-shm \
--disable-libxcb-xfixes \
--disable-libxcb-shape"

fi

if [ "$DEBUG" ]
then
    CONFIGURE_FLAGS="$CONFIGURE_FLAGS --enable-debug --disable-stripping --disable-optimizations"
else
    CONFIGURE_FLAGS="$CONFIGURE_FLAGS --disable-debug --enable-stripping --enable-optimizations"
fi

if [ "$BUILD_EXT" == "watchos" ]
then
    CONFIGURE_FLAGS="$CONFIGURE_FLAGS --disable-libass --disable-libaom --disable-asm"
elif [ "$BUILD_EXT" == "maccatalyst" ]
then
    CONFIGURE_FLAGS="$CONFIGURE_FLAGS --enable-libaom --disable-asm --enable-libzvbi --enable-videotoolbox"
else
    CONFIGURE_FLAGS="$CONFIGURE_FLAGS --enable-libaom --enable-libzvbi --enable-videotoolbox"
fi

echo $CONFIGURE_FLAGS

download_deps

echo "building..."
mkdir -p "$SCRATCH"
cd "$SCRATCH"

# force "configure" to use "gas-preprocessor.pl" (FFmpeg 3.3)
if [ "$ARCH" = "arm64" -o "$ARCH" = "arm64-simulator" ]
then
    real_arch="arm64"
    AS="gas-preprocessor.pl -arch aarch64 -- $CC"
else
    real_arch=$ARCH
    AS="gas-preprocessor.pl -- $CC"
fi

TMPDIR=${TMPDIR/%\/} $CWD/$SOURCE/configure \
    --target-os=darwin \
    --arch="${real_arch}" \
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

make clean
make -j4 install || exit 1
cd $CWD

echo Done
