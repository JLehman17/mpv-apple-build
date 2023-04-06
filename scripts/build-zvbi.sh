#!/bin/sh

ARCH=$1

# directories
ZVBI_VERSION="0.2.35"
SOURCE="src/zvbi-$ZVBI_VERSION"
BUILD="$BUILD_DIR/$BUILD_EXT/$ARCH/scratch/zvbi"
SCRATCH=$BUILD/"build"
# must be an absolute path
PREFIX=`pwd`/$BUILD

if [ ! -r $SOURCE ]
then
    echo 'zvbi source not found. Trying to download...'
    cd src
    curl -L https://sourceforge.net/projects/zapping/files/zvbi/"$ZVBI_VERSION"/zvbi-"$ZVBI_VERSION".tar.bz2/download | tar xj || exit 1
    cd $ROOT_DIR
    
    cd $SOURCE
    echo "Applying patches..."
    PATCH="$ROOT_DIR/patches/zvbi/Makefile.in.patch"
    cp $PATCH ./ &&
    patch -p0 < "Makefile.in.patch" && rm "./Makefile.in.patch" || exit 1
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
--disable-rpath \
--without-doxygen \
--without-x \
--host=${host} \
"

echo "Configuring with options $CONFIGURE_FLAGS"

TMPDIR=${TMPDIR/%\/} $CWD/$SOURCE/configure \
    $CONFIGURE_FLAGS \
    --prefix="$PREFIX" \
    --libdir="$CWD/$BUILD_DIR/$BUILD_EXT/$ARCH/lib" \
    --includedir="$CWD/$BUILD_DIR/$BUILD_EXT/$ARCH/include" \
|| exit 1

make -j4 install || exit 1
cd $CWD

echo Done
