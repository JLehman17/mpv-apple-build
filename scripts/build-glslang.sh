#!/bin/sh

# directories
VERSION="14.1.0"
SOURCE="src/glslang-$VERSION"

ARCH=$1

# Use this patch for pkg-config file generation:
# https://src.fedoraproject.org/rpms/glslang/blob/rawhide/f/0001-pkg-config-compatibility.patch
# Also see:
# https://github.com/KhronosGroup/glslang/pull/3371

BUILD_OUT="$BUILD_DIR/$BUILD_EXT/$ARCH/scratch/glslang"
SCRATCH=$BUILD_OUT/"build"
PREFIX=$ROOT_DIR/$BUILD_OUT

CWD=`pwd`
root=$(pwd)

function download_deps() {
    if [ ! -r $SOURCE ]
    then
        echo "glslang source not found. Trying to download..."
        
        cd src
        git clone https://github.com/KhronosGroup/glslang.git "glslang-${VERSION}"
        cd "glslang-${VERSION}"
        git checkout "${VERSION}"
        
#        ./update_glslang_sources.py
        
#        echo "Applying pkg-config patch..."
#        patch="$PATCHES/glslang/pkg-config-compatibility.patch"
#        cp $patch ./ &&
#        git apply "pkg-config-compatibility.patch" && rm "./pkg-config-compatibility.patch" || exit 1

        cd $ROOT_DIR
    fi
}

download_deps

cd ./$SOURCE/

cwd=$(pwd)

echo "Building..."

ARCH="${ARCH}"
ARCH_OPTIONS="-DARCH_X86_64=0 -DENABLE_SSE=0 -DENABLE_SSE2=0 -DENABLE_SSE3=0 -DENABLE_SSE4_1=0 -DENABLE_SSE4_2=0 -DENABLE_MMX=0 -DCONFIG_OS_SUPPORT=0 -DCONFIG_RUNTIME_CPU_DETECT=0"

XCRUN_SDK=`echo $PLATFORM | tr '[:upper:]' '[:lower:]'`
SYSROOT=$(xcrun --sdk $XCRUN_SDK --show-sdk-path)
CC="xcrun -sdk $XCRUN_SDK clang -isysroot=$SYSROOT"
CXX="xcrun -sdk $XCRUN_SDK clang++ -isysroot=$SYSROOT"
#CC="clang"
#CXX="clang++"

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
elif [ "$BUILD_EXT" == "maccatalyst" ]
then
    if [ "$ARCH" = "arm64" -o "$ARCH" = "arm64-simulator" ]
    then
        ARCH_OPTIONS="-DARCH_ARM=1 -DENABLE_NEON=1 -DHAVE_NEON=1"
    else
        ARCH_OPTIONS="-DARCH_X86_64=1 -DENABLE_SSE4_1=1 -DHAVE_SSE4_2=1"
    fi
fi

TOOLCHAIN_FILE="$ROOT_DIR/tools/glslang/${real_arch}-${BUILD_EXT}.cmake"

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

cmake "${ROOT_DIR}/${SOURCE}" -Wno-dev \
    -DENABLE_OPT=0 \
    -DCMAKE_VERBOSE_MAKEFILE=0 \
    -DCONFIG_PIC=1 \
    -DCMAKE_C_FLAGS="${CFLAGS}" \
    -DCMAKE_CXX_FLAGS="${CXXFLAGS}" \
    -DCMAKE_EXE_LINKER_FLAGS="${LDFLAGS}" \
    -DCMAKE_SYSROOT="${SYSROOT}" \
    -DCMAKE_FIND_ROOT_PATH="${SYSROOT}" \
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

make -j4 install || exit 1
cd $CWD

echo Done
