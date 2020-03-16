#!/bin/sh

BUILD_DIR="build/release"
CWD=`pwd`

function ConfigureForMacCatalyst() {

    PLATFORM="macosx"
    BUILD_EXT="macOS"
    
    export PATH="/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/:$PATH"
    export SDKPATH="$(xcodebuild -sdk $PLATFORM -version Path)"
    
    XCRUN_SDK=`echo $PLATFORM | tr '[:upper:]' '[:lower:]'`
    export CC="xcrun -sdk $XCRUN_SDK clang"
    export CXX="xcrun -sdk $XCRUN_SDK clang++"
    export CPP="$CC -E"
    export AR=$(xcrun -sdk $XCRUN_SDK -find ar)
    
    export CFLAGS="-isysroot $SDKPATH -target x86_64-apple-ios13.0-macabi \
            -I$CWD/$BUILD_DIR/$BUILD_EXT/include"
    export LDFLAGS="-isysroot $SDKPATH -target x86_64-apple-ios13.0-macabi \
            -L$CWD/$BUILD_DIR/$BUILD_EXT/lib"
    export CXXFLAGS="$CFLAGS"
    export CPPFLAGS="$CFLAGS"
    
#    export PKG_CONFIG_SYSROOT_DIR="$CWD/$BUILD_DIR/$BUILD_EXT"
    export PKG_CONFIG_LIBDIR="$CWD/$BUILD_DIR/$BUILD_EXT/lib/pkgconfig"
}
