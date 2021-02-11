#!/bin/sh

ARCH=$1

LIBASS_VERSION="0.14.0"
SOURCE="src/libass-$LIBASS_VERSION"

BUILD_OUT="$BUILD_DIR/$BUILD_EXT/$ARCH/scratch/libass"
SCRATCH=$BUILD_OUT/"build"
PREFIX=$ROOT_DIR/$BUILD_OUT

if [ ! -r $SOURCE ]
then
    echo "libass source not found. Attempting to download..."
    cd src
    curl -L "https://github.com/libass/libass/releases/download/$LIBASS_VERSION/libass-$LIBASS_VERSION.tar.gz" | tar -xj || exit 1
    cd $ROOT_DIR
fi

CWD=`pwd`
echo "building..."
mkdir -p "$SCRATCH"
cd "$SCRATCH"

config_guess=$ROOT_DIR/$SOURCE/config.guess
build=$($config_guess)

if [ "$ARCH" = "arm64" ]
then
    host="arm-apple-darwin"
else
    host="x86_64-apple-darwin"
fi

#--build=BUILD     configure for building on BUILD [guessed]
#--host=HOST       cross-compile to build programs to run on HOST [BUILD]

CONFIGURE_FLAGS=" \
--disable-shared \
--enable-static \
--disable-fontconfig \
--build=$build \
--host=$host \
"
#--disable-coretext \
#--disable-require-system-font-provider \

echo "Configuring with options $CONFIGURE_FLAGS"

$CWD/$SOURCE/configure $CONFIGURE_FLAGS \
     --prefix="$PREFIX" \
     --libdir="$CWD/$BUILD_DIR/$BUILD_EXT/$ARCH/lib" \
     --includedir="$CWD/$BUILD_DIR/$BUILD_EXT/$ARCH/include" \
 || exit 1

make -j$get_cpu_count install || exit 1

echo Done
