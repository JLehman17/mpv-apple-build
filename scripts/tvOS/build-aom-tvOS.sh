#!/bin/sh

source config.sh

ARCHS="arm64 x86_64"

CWD=`pwd`
SOURCE="src/aom"

function downloadDeps() {
    if [ ! -r $SOURCE ]
    then
        echo 'aom source not found. Trying to download...'
        cd src
        git clone https://aomedia.googlesource.com/aom
        cd ..
    fi
}

for toolchain in $(find $CWD/tools/aom/ -iname "*tvos*"); do
    cp $toolchain "${SOURCE}/build/cmake/toolchains/"
done

downloadDeps

cd ./$SOURCE/

cwd=$(pwd)
for ARCH in $ARCHS
do
    echo "Building $ARCH..."
    
    config_for_tvos $ARCH
    
    cd ${cwd}

    if [ "$ARCH" = "i386" -o "$ARCH" = "x86_64" ]
    then
        ARCH_OPTIONS="-DARCH_X86_64=1 -DENABLE_SSE4_1=1 -DHAVE_SSE4_2=1"
        sim="-simulator"
    else
        ARCH_OPTIONS="-DARCH_ARM=1 -DENABLE_NEON=1 -DHAVE_NEON=1"
    fi

    TOOLCHAIN_FILE="build/cmake/toolchains/${ARCH}-tvos${sim}.cmake"

    scratch="${CWD}/${BUILD_DIR}/${BUILD_EXT}/scratch/aom/${ARCH}"
    prefix="${CWD}/${BUILD_DIR}/${BUILD_EXT}/thin/${ARCH}"
    
#    rm -r $scratch
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
        -DCMAKE_AS="$CC" \
        -DCMAKE_TOOLCHAIN_FILE=${TOOLCHAIN_FILE} \
        ${ARCH_OPTIONS} \
        -DENABLE_TESTS=0 \
        -DENABLE_EXAMPLES=0 \
        -DENABLE_TOOLS=0 \
        -DCONFIG_UNIT_TESTS=0 \
        -DBUILD_SHARED_LIBS=0 .. || exit 1
        
    make install -j$(get_cpu_count) || exit 1

done

cd ..

echo Done


