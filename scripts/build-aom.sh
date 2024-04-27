#!/bin/sh


DEPLOYMENT_TARGET="11.0.0"

CWD=`pwd`
SOURCE="src/aom-${BUILD_EXT}"
ARCH=$1

root=$(pwd)

function downloadDeps() {
    if [ ! -r $SOURCE ]
    then
        echo 'aom source not found. Trying to download...'
        git clone https://aomedia.googlesource.com/aom $SOURCE
        cd $ROOT_DIR
    fi
}

downloadDeps

cd ./$SOURCE/

cwd=$(pwd)

ARCH="${ARCH}"
ARCH_OPTIONS="-DARCH_X86_64=0 -DENABLE_SSE=0 -DENABLE_SSE2=0 -DENABLE_SSE3=0 -DENABLE_SSE4_1=0 -DENABLE_SSE4_2=0 -DENABLE_MMX=0 -DCONFIG_OS_SUPPORT=0 -DCONFIG_RUNTIME_CPU_DETECT=0"

XCRUN_SDK=`echo $PLATFORM | tr '[:upper:]' '[:lower:]'`
SYSROOT=$(xcrun --sdk $XCRUN_SDK --show-sdk-path)
CC="xcrun -sdk $XCRUN_SDK clang -isysroot=$SYSROOT"
CXX="xcrun -sdk $XCRUN_SDK clang++ -isysroot=$SYSROOT"

AS="$CC"
CXXFLAGS="$CFLAGS"
LDFLAGS="$CFLAGS"

if [ "$ARCH" = "arm64" -o "$ARCH" = "arm64-simulator" ]
then
    real_arch="arm64"
else
    real_arch=$ARCH
fi

# TODO: Support ios arm64 simulator builds
if [ "$PLATFORM" == "iphonesimulator" -o "$PLATFORM" == "appletvsimulator" ]
then
    sim="-simulator"
    ARCH_OPTIONS="-DARCH_X86_64=1 -DENABLE_SSE4_1=1 -DHAVE_SSE4_2=1"
    
elif [ "$PLATFORM" == "iphoneos" -o "$PLATFORM" == "appletvos" ]
then
    ARCH_OPTIONS="-DARCH_ARM=1 -DENABLE_NEON=1 -DHAVE_NEON=1"
fi

# Copy toolchain files

if [ "$BUILD_EXT" == "ios" ]
then
    TOOLCHAIN_FILE="build/cmake/toolchains/${ARCH}-ios${sim}.cmake"
    
elif [ "$BUILD_EXT" == "maccatalyst" ]
then
    cp "$root/tools/aom/libaom.${ARCH}-mac-catalyst.cmake" "build/cmake/toolchains/"
    TOOLCHAIN_FILE="build/cmake/toolchains/libaom.${ARCH}-mac-catalyst.cmake"
elif [ "$BUILD_EXT" == "tvos" ]
then
    cp "$root/tools/aom/arm-tvos-common.cmake" "build/cmake/toolchains/"
    cp "$root/tools/aom/tvos-simulator-common.cmake" "build/cmake/toolchains/"

    cp "$root/tools/aom/${real_arch}-tvos-simulator.cmake" "build/cmake/toolchains/"
    cp "$root/tools/aom/${real_arch}-tvos${sim}.cmake" "build/cmake/toolchains/"
    TOOLCHAIN_FILE="build/cmake/toolchains/${real_arch}-tvos${sim}.cmake"
fi

# clean
cmake_build="${root}/${SOURCE}/cmake-build"
if [ -d $cmake_build ]
then
    rm -r $cmake_build
fi

build="${cwd}/cmake-build"
scratch="${build}/scratch/${ARCH}"
prefix="${root}/${BUILD_DIR}/${BUILD_EXT}/${ARCH}"

mkdir -p $scratch
cd $scratch

cmake "${cwd}" -Wno-dev \
    -DCMAKE_VERBOSE_MAKEFILE=0 \
    -DCONFIG_PIC=1 \
    -DCMAKE_C_FLAGS="${CFLAGS}" \
    -DCMAKE_CXX_FLAGS="${CXXFLAGS}" \
    -DCMAKE_EXE_LINKER_FLAGS="${LDFLAGS}" \
    -DCMAKE_SYSROOT="${SDKPATH}" \
    -DCMAKE_FIND_ROOT_PATH="${SDKPATH}" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="${prefix}" \
    -DCMAKE_CXX_COMPILER="$CXX" \
    -DCMAKE_C_COMPILER="$CC" \
    -DCMAKE_LINKER="$LD" \
    -DCMAKE_AR="$(xcrun --sdk ${PLATFORM} -f ar)" \
    -DCMAKE_AS="$AS" \
    -DCMAKE_TOOLCHAIN_FILE=${TOOLCHAIN_FILE} \
    ${ARCH_OPTIONS} \
    -DENABLE_TESTS=0 \
    -DENABLE_EXAMPLES=0 \
    -DENABLE_TOOLS=0 \
    -DCONFIG_UNIT_TESTS=0 \
    -DBUILD_SHARED_LIBS=0 .. || exit 1
    
make install -j4 || exit 1

cd ..

echo Done


