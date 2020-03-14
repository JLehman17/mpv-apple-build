#!/bin/sh

HARFBUZZ_VERSION="2.2.0"
SOURCE="harfbuzz-$HARFBUZZ_VERSION"
BUILD="Harfbuzz-iOS"
THIN=`pwd`/$BUILD/"thin"

ARCHS="arm64"

COMPILE="y"
LIPO="y"

DEPLOYMENT_TARGET="9.0"

if [ "$*" ]
then
    if [ "$*" = "lipo" ]
    then
        # skip compile
        COMPILE=
    else
        ARCHS="$*"
        if [ $# -eq 1 ]
        then
            # skip lipo
            LIPO=
        fi
    fi
fi

if [ "$COMPILE" ]
then

    if [ ! -r $SOURCE ]
    then
        echo "harfbuzz source not found. Attempting to download..."
        curl -L "https://www.freedesktop.org/software/harfbuzz/release/$SOURCE.tar.bz2" | tar -xj || exit 1
    fi

    cd ./$SOURCE

    for ARCH in $ARCHS
    do

        echo "building $ARCH..."

        if [ "$ARCH" = "i386" -o "$ARCH" = "x86_64" ]
        then
            PLATFORM="iphonesimulator"
        else
            PLATFORM="iphoneos"
        fi

        export PATH="/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/:$PATH"
        export SDKPATH="$(xcodebuild -sdk $PLATFORM -version Path)"
        export CFLAGS="-isysroot $SDKPATH -arch $ARCH -mios-version-min=$DEPLOYMENT_TARGET"
#        export CPPFLAGS="-mios-version-min=$DEPLOYMENT_TARGET"
        export LDFLAGS="-isysroot $SDKPATH -arch $ARCH -L/Users/Josh/Projects/Emby/emby-ios/platforms/ios/libs/"
        export CC="$(xcrun -find -sdk iphoneos clang)"
        export CXX="$(xcrun -find -sdk iphoneos clang++)"
#export CC="$(which gcc)"
#export CXX="$(which g++)"
#        export LT_SYS_LIBRARY_PATH="/Users/Josh/Projects/Emby/emby-ios/platforms/ios/libs/"

        CONFIGURE_FLAGS=" \
        --disable-shared \
        --enable-static \
        --disable-gtk-doc-html \
        --with-cairo=no \
        --with-freetype=yes \
        --with-icu=no \
        --with-glib=no \
        --with-fontconfig=no \
        --host=arm-apple-darwin \
        --with-sysroot=$SDKPATH \
        --prefix=$THIN/$ARCH
        "

#CONFIGURE_FLAGS=" \
#--disable-shared \
#--enable-static \
#--disable-gtk-doc-html \
#--with-cairo=no \
#--with-freetype=yes \
#--host=aarch64-apple-darwin \
#--with-sysroot=$SDKPATH \
#--prefix=$THIN/$ARCH
#"

        echo "Configuring with options $CONFIGURE_FLAGS"

#        ./autogen.sh

        make clean
        make distclean

        ./configure $CONFIGURE_FLAGS &&
        make -j3 install || exit 1

    done

    cd ..

fi
