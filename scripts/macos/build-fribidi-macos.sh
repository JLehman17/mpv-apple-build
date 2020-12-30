#!/bin/sh

ARCH=$1

FRIBIDI_VERSION="1.0.9"
SOURCE="src/fribidi-$FRIBIDI_VERSION"

BUILD_OUT="$BUILD_DIR/$BUILD_EXT/$ARCH/scratch/fribidi"
SCRATCH=$BUILD_OUT/"build"
PREFIX=$ROOT_DIR/$BUILD_OUT

if [ ! -r $SOURCE ]
then
    echo "fribidi source not found. Attempting to download..."
    cd src
    curl -L "https://github.com/fribidi/fribidi/releases/download/v$FRIBIDI_VERSION/fribidi-$FRIBIDI_VERSION.tar.xz" | tar -xj || exit 1
    cd $ROOT_DIR
fi

CWD=`pwd`
echo "building..."
mkdir -p "$SCRATCH"
cd "$SCRATCH"

config_guess=$ROOT_DIR/$SOURCE/config.guess
host=$($config_guess)

CONFIGURE_FLAGS=" \
--disable-shared \
--enable-static \
--build=${host} \
"

echo "Configuring with options $CONFIGURE_FLAGS"

#make clean
#make distclean

$CWD/$SOURCE/configure $CONFIGURE_FLAGS \
     --prefix="$PREFIX" \
     --libdir=$CWD/$BUILD_DIR/$BUILD_EXT/$ARCH/lib \
     --includedir=$CWD/$BUILD_DIR/$BUILD_EXT/$ARCH/include \
 || exit 1

make -j4 install || exit 1

echo Done
