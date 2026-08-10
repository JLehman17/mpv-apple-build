#!/bin/sh

# directories
SOURCE="src/openssl-${OPENSSL_VERSION}-${BUILD_EXT}"

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
        mkdir -p $SOURCE &&
        curl -L "https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz" |
            tar xz -C $SOURCE --strip-components 1 || exit 1
        
        cd $ROOT_DIR
    fi
}

download_deps

if [[ "$BUILD_EXT" == "ios" || "$BUILD_EXT" == "tvos" ]]
then
    if [ "$ARCH" = "arm64" -o "$ARCH" = "arm64-simulator" ]
    then
        CONFIGURE_FLAGS="ios64-cross"
    else
        CONFIGURE_FLAGS="darwin64-x86_64-cc"
    fi
fi

if [[ "$BUILD_EXT" == "maccatalyst" ]]
then
    if [ "$ARCH" = "arm64" ]
    then
        CONFIGURE_FLAGS="darwin64-arm64-cc -no-asm"
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
-DHAVE_FORK=0 \
-no-asm \
-no-tests \
"
    pushd "${ROOT_DIR}/${SOURCE}"
    # Patch apps/... to not use fork() since it's not available on tvOS
    grep -q '^#define HAVE_FORK 0$' "./apps/speed.c" || \
        sed -i '' '1s;^;#define HAVE_FORK 0\n;' "./apps/speed.c"
    grep -q '^#define HAVE_FORK 0$' "./apps/include/http_server.h" || \
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
    if [ "${PLATFORM}" = "appletvsimulator" ]
    then
        tvos_version_min_flag="-mtvos-simulator-version-min"
    else
        tvos_version_min_flag="-mtvos-version-min"
    fi
    # Replace the iOS deployment flag inherited from OpenSSL's ios64-cross target.
    sed -i '' "s/-mios-version-min=7.0.0/${tvos_version_min_flag}=${DEPLOYMENT_TARGET_TVOS}/g" "Makefile"
fi

echo "Building..."
make -j$get_cpu_count || exit 1
make install_sw || exit 1

echo Done
