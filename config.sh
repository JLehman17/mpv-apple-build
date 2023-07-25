#!/bin/sh

export BUILD_DIR="build/release"
CWD=`pwd`

export DEPLOYMENT_TARGET_IOS="11.0.0"
export DEPLOYMENT_TARGET_TVOS="14.0.0"
export DEPLOYMENT_TARGET_WATCHOS="7.0.0"

XCODE_PATH=$(xcode-select -p)
export PATH="/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/:$PATH"

if [ ! -r src ]
then
    mkdir src
fi

export ROOT_DIR=$CWD

function config_for_ios() {

    local ARCH=$1
    export BUILD_EXT="ios"
    
    if [ "$ARCH" = "i386" -o "$ARCH" = "x86_64" ]
    then
        PLATFORM="iphonesimulator"
    else
        PLATFORM="iphoneos"
    fi
    export PLATFORM=$PLATFORM
    
    XCRUN_SDK=`echo $PLATFORM | tr '[:upper:]' '[:lower:]'`
    SYSROOT=$(xcrun --sdk $XCRUN_SDK --show-sdk-path)
    export CC="xcrun -sdk $XCRUN_SDK clang -isysroot=$SYSROOT"
    export CXX="xcrun -sdk $XCRUN_SDK clang++ -isysroot=$SYSROOT"
    export CPP="$CC -E"
    export AR=$(xcrun -sdk $XCRUN_SDK -find ar)
    
    export SDKPATH="$(xcodebuild -sdk $PLATFORM -version Path)"
    export CFLAGS="-isysroot $SDKPATH -arch $ARCH -mios-version-min=$DEPLOYMENT_TARGET_IOS -arch $ARCH \
                    -I${CWD}/${BUILD_DIR}/${BUILD_EXT}/${ARCH}/include"
    export LDFLAGS="-isysroot $SDKPATH -arch $ARCH -mios-version-min=$DEPLOYMENT_TARGET_IOS -arch $ARCH \
                    -L${CWD}/${BUILD_DIR}/${BUILD_EXT}/${ARCH}/lib"
    export CXXFLAGS="$CFLAGS"
    export CPPFLAGS="$CFLAGS"
    
    export PKG_CONFIG=pkg-config
    export PKG_CONFIG_PATH="${CWD}/${BUILD_DIR}/${BUILD_EXT}/${ARCH}/lib/pkgconfig"
    
    ensure_build_dir
}

function config_for_watchos() {

    local ARCH=$1
    export BUILD_EXT="watchos"
    
    if [ "$ARCH" = "i386" -o "$ARCH" = "x86_64" ]
    then
        PLATFORM="watchsimulator"
    else
        PLATFORM="watchos"
    fi
    export PLATFORM=$PLATFORM
    
    XCRUN_SDK=`echo $PLATFORM | tr '[:upper:]' '[:lower:]'`
    SYSROOT=$(xcrun --sdk $XCRUN_SDK --show-sdk-path)
    export CC="xcrun -sdk $XCRUN_SDK clang -isysroot=$SYSROOT"
    export CXX="xcrun -sdk $XCRUN_SDK clang++ -isysroot=$SYSROOT"
    export CPP="$CC -E"
    export AR=$(xcrun -sdk $XCRUN_SDK -find ar)
    
    export SDKPATH="$(xcodebuild -sdk $PLATFORM -version Path)"
    export CFLAGS="-isysroot $SDKPATH -arch $ARCH -mwatchos-version-min=$DEPLOYMENT_TARGET_WATCHOS -arch $ARCH \
                    -I${CWD}/${BUILD_DIR}/${BUILD_EXT}/${ARCH}/include -fembed-bitcode"
    export LDFLAGS="-isysroot $SDKPATH -arch $ARCH -mwatchos-version-min=$DEPLOYMENT_TARGET_WATCHOS -arch $ARCH \
                    -L${CWD}/${BUILD_DIR}/${BUILD_EXT}/${ARCH}/lib"
    export CXXFLAGS="$CFLAGS"
    export CPPFLAGS="$CFLAGS"
    
    export PKG_CONFIG=pkg-config
    export PKG_CONFIG_PATH="${CWD}/${BUILD_DIR}/${BUILD_EXT}/${ARCH}/lib/pkgconfig"
    
    ensure_build_dir
}

function config_for_maccatalyst() {

    local ARCH=$1
    if [ "$ARCH" = "arm64" ]
    then
        target="arm64-apple-ios14.0-macabi"
    else
        target="x86_64-apple-ios13.1-macabi"
    fi

    export BUILD_EXT="maccatalyst"
    export PLATFORM="macosx"
    
    export SDKPATH="$(xcodebuild -sdk $PLATFORM -version Path)"
    
    XCRUN_SDK=`echo $PLATFORM | tr '[:upper:]' '[:lower:]'`
    export CC="xcrun -sdk $XCRUN_SDK clang"
    export CXX="xcrun -sdk $XCRUN_SDK clang++"
    export CPP="$CC -E"
    export AR=$(xcrun -sdk $XCRUN_SDK -find ar)
    
    export CFLAGS="-isysroot $SDKPATH -target $target -arch $ARCH \
            -I$CWD/$BUILD_DIR/$BUILD_EXT/${ARCH}/include"
    export LDFLAGS="-isysroot $SDKPATH -target $target -arch $ARCH \
            -L$CWD/$BUILD_DIR/$BUILD_EXT/${ARCH}/lib"
    export CXXFLAGS="$CFLAGS"
    export CPPFLAGS="$CFLAGS"
    
    export PKG_CONFIG=pkg-config
    export PKG_CONFIG_PATH="${CWD}/${BUILD_DIR}/${BUILD_EXT}/${ARCH}/lib/pkgconfig"
    
    ensure_build_dir
}

function config_for_macos() {

    local ARCH=$1

    export PLATFORM="macosx"
    export BUILD_EXT="macos"
    
    export SDKPATH="$(xcodebuild -sdk $PLATFORM -version Path)"
    
    XCRUN_SDK=`echo $PLATFORM | tr '[:upper:]' '[:lower:]'`
    export CC="xcrun -sdk $XCRUN_SDK clang"
    export CXX="xcrun -sdk $XCRUN_SDK clang++"
    export CPP="$CC -E"
    export AR=$(xcrun -sdk $XCRUN_SDK -find ar)
    
    export CFLAGS="-isysroot $SDKPATH -arch $ARCH \
            -I$CWD/$BUILD_DIR/$BUILD_EXT/${ARCH}/include"
    export LDFLAGS="-isysroot $SDKPATH -arch $ARCH \
            -L$CWD/$BUILD_DIR/$BUILD_EXT/${ARCH}/lib"
    export CXXFLAGS="$CFLAGS"
    export CPPFLAGS="$CFLAGS"
    
    export PKG_CONFIG=pkg-config
    export PKG_CONFIG_PATH="${CWD}/${BUILD_DIR}/${BUILD_EXT}/${ARCH}/lib/pkgconfig"
    
    ensure_build_dir
}

function config_for_tvos() {
    
    local ARCH=$1
    local arch_name=$ARCH
    export BUILD_EXT="tvos"
    
    if [ "$ARCH" = "arm64-simulator" -o "$ARCH" = "x86_64" ]
    then
        PLATFORM="appletvsimulator"
        if [ "$ARCH" = "arm64-simulator" ]
        then
            ARCH="arm64"
            target="arm64-apple-tvos14.0-simulator"
        else
            target="x86_64-apple-tvos14.0-simulator"
        fi
    else
        PLATFORM="appletvos"
        target="arm64-apple-tvos14.0"
    fi
    export PLATFORM=$PLATFORM
    
    XCRUN_SDK=`echo $PLATFORM | tr '[:upper:]' '[:lower:]'`
    SYSROOT=$(xcrun --sdk $XCRUN_SDK --show-sdk-path)
    export CC="xcrun -sdk $XCRUN_SDK clang -isysroot=$SYSROOT"
    export CXX="xcrun -sdk $XCRUN_SDK clang++ -isysroot=$SYSROOT"
    export CPP="$CC -E"
    export AR=$(xcrun -sdk $XCRUN_SDK -find ar)
    
    export SDKPATH="$(xcodebuild -sdk $PLATFORM -version Path)"
    export CFLAGS="-isysroot $SDKPATH -target $target -arch $ARCH \
                    -mtvos-version-min=$DEPLOYMENT_TARGET_TVOS -fembed-bitcode \
                    -I${CWD}/${BUILD_DIR}/${BUILD_EXT}/${arch_name}/include"
    export LDFLAGS="-isysroot $SDKPATH -target $target -arch $ARCH \
                    -mtvos-version-min=$DEPLOYMENT_TARGET_TVOS \
                    -L${CWD}/${BUILD_DIR}/${BUILD_EXT}/${arch_name}/lib"
    export CXXFLAGS="$CFLAGS"
    export CPPFLAGS="$CFLAGS"
    
    export PKG_CONFIG=pkg-config
    export PKG_CONFIG_PATH="${CWD}/${BUILD_DIR}/${BUILD_EXT}/${arch_name}/lib/pkgconfig"
    
    ensure_build_dir
}

function ensure_build_dir() {
    if [ ! -r $BUILD_DIR/$BUILD_EXT ]
    then
        mkdir -p $BUILD_DIR/$BUILD_EXT
    fi
}

function get_cpu_count() {
  if [ "$(uname)" == "Darwin" ]; then
    echo $(sysctl -n hw.physicalcpu)
  else
    echo $(nproc)
  fi
}
