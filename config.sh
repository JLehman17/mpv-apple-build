#!/bin/sh

export BUILD_DIR="build/release"
CWD=`pwd`

DEPLOYMENT_TARGET_TVOS="9.0.0"

XCODE_PATH=$(xcode-select -p)
export PATH="/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/:$PATH"

function ConfigureForMacCatalyst() {

    ARCH=$1
    if [ "$ARCH" = "arm64" ]
    then
        target="arm64-apple-ios13.0-macabi"
    else
        target="x86_64-apple-ios13.0-macabi"
    fi

    export PLATFORM="macosx"
    export BUILD_EXT="maccatalyst"
    
    export SDKPATH="$(xcodebuild -sdk $PLATFORM -version Path)"
    
    XCRUN_SDK=`echo $PLATFORM | tr '[:upper:]' '[:lower:]'`
    export CC="xcrun -sdk $XCRUN_SDK clang"
    export CXX="xcrun -sdk $XCRUN_SDK clang++"
    export CPP="$CC -E"
    export AR=$(xcrun -sdk $XCRUN_SDK -find ar)
    
    export CFLAGS="-isysroot $SDKPATH -target $target \
            -I$CWD/$BUILD_DIR/$BUILD_EXT/include"
    export LDFLAGS="-isysroot $SDKPATH -target $target \
            -L$CWD/$BUILD_DIR/$BUILD_EXT/lib"
    export CXXFLAGS="$CFLAGS"
    export CPPFLAGS="$CFLAGS"
    
#    export PKG_CONFIG_SYSROOT_DIR="$CWD/$BUILD_DIR/$BUILD_EXT"
    export PKG_CONFIG_LIBDIR="$CWD/$BUILD_DIR/$BUILD_EXT/$ARCH/lib/pkgconfig"
}

function config_for_tvos() {
    
    local ARCH=$1
    export BUILD_EXT="tvOS"
    
    if [ "$ARCH" = "i386" -o "$ARCH" = "x86_64" ]
    then
        PLATFORM="appletvsimulator"
    else
        PLATFORM="appletvos"
    fi
    export PLATFORM=$PLATFORM
    
    XCRUN_SDK=`echo $PLATFORM | tr '[:upper:]' '[:lower:]'`
    SYSROOT=$(xcrun --sdk $XCRUN_SDK --show-sdk-path)
    export CC="xcrun -sdk $XCRUN_SDK clang -isysroot=$SYSROOT"
    export CXX="xcrun -sdk $XCRUN_SDK clang++ -isysroot=$SYSROOT"
    export CPP="$CC -E"
    export AR=$(xcrun -sdk $XCRUN_SDK -find ar)
    
    export SDKPATH="$(xcodebuild -sdk $PLATFORM -version Path)"
    export CFLAGS="-isysroot $SDKPATH -arch $ARCH -mtvos-version-min=$DEPLOYMENT_TARGET_TVOS -fembed-bitcode \
                    -I${CWD}/${BUILD_DIR}/tvOS/thin/${ARCH}/include"
    export LDFLAGS="-isysroot $SDKPATH -arch $ARCH -mtvos-version-min=$DEPLOYMENT_TARGET_TVOS \
                    -L${CWD}/${BUILD_DIR}/tvOS/thin/${ARCH}/lib"
    export CXXFLAGS="$CFLAGS"
    export CPPFLAGS="$CFLAGS"
    
    export PKG_CONFIG_SYSROOT_DIR="${BUILD_DIR}/tvOS/thin"
    export PKG_CONFIG_LIBDIR="$PKG_CONFIG_SYSROOT_DIR/$ARCH/lib/pkgconfig"
}

function get_cpu_count() {
  if [ "$(uname)" == "Darwin" ]; then
    echo $(sysctl -n hw.physicalcpu)
  else
    echo $(nproc)
  fi
}
