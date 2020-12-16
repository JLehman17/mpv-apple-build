#!/bin/sh


ARCHS="arm64 x86_64"
DEPLOYMENT_TARGET="11.0.0"

CWD=`pwd`
SOURCE="aom"


#DEBUG=
#BUILD_DIR="build/release/mpv-iOS"
#while getopts d option
#do
#    case "${option}" in
#        d) DEBUG="y"
#           BUILD_DIR="build/mpv-iOS/debug"
#           shift;;
#    esac
#done
#
#THIN=$CWD/$BUILD_DIR/"thin"
#SCRATCH=$CWD/$BUILD_DIR/"scratch"
#FFMPEG_BUILD=$BUILD_DIR/"ffmpeg-iOS"

function downloadDeps() {
    if [ ! -r $SOURCE ]
    then
        echo 'aom source not found. Trying to download...'
        git clone https://aomedia.googlesource.com/aom
    fi
}

downloadDeps

cd ./$SOURCE/

cwd=$(pwd)
for ARCH in $ARCHS
do
    echo "Building $ARCH..."
    
    cd ${cwd}

    if [ "$ARCH" = "i386" -o "$ARCH" = "x86_64" ]
    then
        PLATFORM="iphonesimulator"
        sim="-simulator"
        ARCH_OPTIONS="-DARCH_X86_64=1 -DENABLE_SSE4_1=1 -DHAVE_SSE4_2=1"
    else
        PLATFORM="iphoneos"
        ARCH_OPTIONS="-DARCH_ARM=1 -DENABLE_NEON=1 -DHAVE_NEON=1"
    fi

    export PATH="/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/:$PATH"
    export SDKPATH="$(xcodebuild -sdk $PLATFORM -version Path)"
    export CFLAGS="-isysroot $SDKPATH -arch $ARCH -mios-version-min=$DEPLOYMENT_TARGET -fembed-bitcode \
                    -I$CWD/build/release/libs-iOS/include"
    export LDFLAGS="-isysroot $SDKPATH -arch $ARCH -Wl,-ios_version_min,$DEPLOYMENT_TARGET -lbz2 \
                    -L$CWD/build/release/libs-iOS/$ARCH"
    
    XCRUN_SDK=`echo $PLATFORM | tr '[:upper:]' '[:lower:]'`
    SYSROOT=$(xcrun --sdk $XCRUN_SDK --show-sdk-path)
    CC="xcrun -sdk $XCRUN_SDK clang -isysroot=$SYSROOT"
    CXX="xcrun -sdk $XCRUN_SDK clang++ -isysroot=$SYSROOT"
    
    AS="$CC"
    CXXFLAGS="$CFLAGS"
    LDFLAGS="$CFLAGS"
    
#        export PKG_CONFIG_SYSROOT_DIR="$CWD/build/release/libs-iOS"
#        export PKG_CONFIG_LIBDIR="$PKG_CONFIG_SYSROOT_DIR/$ARCH/pkgconfig"

    TOOLCHAIN_FILE="build/cmake/toolchains/${ARCH}-ios${sim}.cmake"

    build="${cwd}/cmake-build"
    scratch="${build}/scratch/${ARCH}"
    prefix="${cwd}/../build/release/libs-iOS/${ARCH}"
    
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

done

cd ..

echo Done


