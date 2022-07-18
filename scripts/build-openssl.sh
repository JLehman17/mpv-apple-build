#!/bin/sh

# directories
VERSION="3.0.3"
SOURCE="src/openssl-${VERSION}-${BUILD_EXT}"

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

BUILD_OUT="$BUILD_DIR/$BUILD_EXT/$ARCH/scratch/openssl"
SCRATCH=$BUILD_OUT/"build"
PREFIX=$ROOT_DIR/$BUILD_OUT

PATCHES=$ROOT_DIR/patches/openssl

function download_deps() {
    if [ ! -r $SOURCE ]
    then
        echo "OpenSSL source not found. Trying to download..."
        mkdir -p $SOURCE && curl "https://www.openssl.org/source/openssl-${VERSION}.tar.gz" | tar -xj -C $SOURCE --strip-components 1 ||
            ( rm ./$SOURCE && exit 1 )
        cd $ROOT_DIR
    fi
}

download_deps

if [[ "$BUILD_EXT" == "ios" || "$BUILD_EXT" == "tvos" ]]
then
    if [ "$ARCH" = "arm64" ]
    then
        CONFIGURE_FLAGS="ios64-cross"
    else
        CONFIGURE_FLAGS="darwin64-x86_64-cc"
    fi
fi

CONFIGURE_FLAGS=" ${CONFIGURE_FLAGS} \
-no-shared \
-no-module"

if [ "$DEBUG" ]
then
    CONFIGURE_FLAGS=" ${CONFIGURE_FLAGS} \
--debug"
else
    CONFIGURE_FLAGS=" ${CONFIGURE_FLAGS} \
--release"
fi

if [[ "${BUILD_EXT}" == "tvos" ]]
then
    # See https://github.com/openssl/openssl/issues/7607
        CONFIGURE_FLAGS=" ${CONFIGURE_FLAGS} \
-DHAVE_FORK=0"
    pushd "${ROOT_DIR}/${SOURCE}"
    # Patch apps/... to not use fork() since it's not available on tvOS
    sed -i '' '1s;^;#define HAVE_FORK 0\n;' "./apps/speed.c"
    sed -i '' '1s;^;#define HAVE_FORK 0\n;' "./apps/include/http_server.h"
    # Patch Configure to build for tvOS, not iOS
    sed -i '' 's/D\_REENTRANT\:iOS/D\_REENTRANT\:tvOS/' "./Configure"
    popd
fi

echo "Configuring with options ${CONFIGURE_FLAGS}"

CWD=`pwd`
mkdir -p "$SCRATCH"
cd "$SCRATCH"

#OpenSSL specific environment variables
#CROSS_COMPILE=`xcode-select --print-path`/Toolchains/XcodeDefault.xctoolchain/usr/bin/
#CROSS_TOP=`xcode-select --print-path`/Platforms/iPhoneOS.platform/Developer
#CROSS_SDK=iPhoneOS.sdk

$CWD/$SOURCE/Configure $CONFIGURE_FLAGS \
     --prefix="$PREFIX" \
     --libdir="$CWD/$BUILD_DIR/$BUILD_EXT/$ARCH/lib" \
 || exit 1
 
if [[ "${BUILD_EXT}" == "tvos" ]]
then
    # Change mios-version-min to mtvos-version-min
    sed -i '' "s/-mios-version-min=7.0.0/-mtvos-version-min=${DEPLOYMENT_TARGET_TVOS}/g" "Makefile"
fi

echo "Building..."
make -j$get_cpu_count || exit 1
make install_sw || exit 1

echo Done
