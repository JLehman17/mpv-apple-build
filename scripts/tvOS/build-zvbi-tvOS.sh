#!/bin/sh

#    If you checked out the sources from CVS, run "./autogen.sh" to create
#    missing configuration and make files.
#
#    To build and install type "./configure", "make", "make check" if you
#    want to run some tests, and "make install".

source config.sh

# directories
ZVBI_VERSION="0.2.35"
SOURCE="src/zvbi-$ZVBI_VERSION"
CWD=`pwd`
PATCHES=$CWD/patches/zvbi


CONFIGURE_FLAGS=" \
--disable-shared \
--disable-rpath \
--without-doxygen \
"

echo $CONFIGURE_FLAGS

ARCHS="arm64 x86_64"

if [ ! -r $SOURCE ]
then
    echo 'zvbi source not found. Trying to download...'
    
    cd src
    curl -L https://sourceforge.net/projects/zapping/files/zvbi/"$ZVBI_VERSION"/zvbi-"$ZVBI_VERSION".tar.bz2/download | tar xj || exit 1

    # Apply patches
    echo "Applying Makefile.am patch..."
    cd "zvbi-${ZVBI_VERSION}"
    cp $PATCHES/Makefile.in.patch ./ &&
    patch -p0 < ./Makefile.in.patch || exit 1
    
    automake
    
    cd $CWD
fi

for ARCH in $ARCHS
do
    echo "building $ARCH..."
    
    config_for_tvos $ARCH
    
    scratch="${CWD}/${BUILD_DIR}/${BUILD_EXT}/scratch/zvbi/${ARCH}"
    prefix="${CWD}/${BUILD_DIR}/${BUILD_EXT}/thin/${ARCH}"
    
    mkdir -p ${scratch}
    cd ${scratch}

    TMPDIR=${TMPDIR/%\/} $CWD/$SOURCE/configure \
        $CONFIGURE_FLAGS \
        --host="arm-apple-darwin" \
        --prefix="${prefix}" \
        || exit 1

     make -j$(get_cpu_count) install || exit 1
     
    cd $CWD
done

echo Done
