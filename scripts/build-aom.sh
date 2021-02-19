#!/bin/sh


DEPLOYMENT_TARGET="11.0.0"

CWD=`pwd`
SOURCE="src/aom"
ARCH=$1

root=$(pwd)

function downloadDeps() {
    if [ ! -r $SOURCE ]
    then
        echo 'aom source not found. Trying to download...'
        cd src
        git clone https://aomedia.googlesource.com/aom
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

cp "$root/tools/aom/libaom.${ARCH}-mac-catalyst.cmake" "build/cmake/toolchains/"
TOOLCHAIN_FILE="build/cmake/toolchains/libaom.${ARCH}-mac-catalyst.cmake"

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


