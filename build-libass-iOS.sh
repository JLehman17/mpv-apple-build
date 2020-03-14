#!/bin/sh

# directories
ZVBI_VERSION="0.2.35"
SOURCE="zvbi-$ZVBI_VERSION"
FAT="zvbi-iOS"
SCRATCH=$FAT/"scratch"
# must be an absolute path
THIN=`pwd`/$FAT/"thin"


CONFIGURE_FLAGS=" \
--disable-shared \
--disable-rpath \
--without-doxygen \
"
#--enable-cross-compile \
#--disable-debug \
#--disable-programs \
#--disable-doc \
#--disable-symver \
#--enable-pic \
#--disable-shared \
#--enable-static \
#--enable-gpl \
#"

echo $CONFIGURE_FLAGS


ARCHS="arm64 x86_64"

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
echo 'zvbi source not found. Trying to download...'
curl https://sourceforge.net/projects/zapping/files/zvbi/"$ZVBI_VERSION"/zvbi-"$ZVBI_VERSION".tar.bz2/download | tar xj || exit 1
fi

CWD=`pwd`
for ARCH in $ARCHS
do
echo "building $ARCH..."
mkdir -p "$SCRATCH/$ARCH"
cd "$SCRATCH/$ARCH"

if [ "$ARCH" = "i386" -o "$ARCH" = "x86_64" ]
then
PLATFORM="iphonesimulator"
else
PLATFORM="iphoneos"
if [ "$ARCH" = "arm64" ]
then
EXPORT="GASPP_FIX_XCODE5=1"
fi
fi

export PATH="/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/:$PATH"
export SDKPATH="$(xcodebuild -sdk $PLATFORM -version Path)"
export CFLAGS="-arch $ARCH -isysroot $SDKPATH -mios-version-min=$DEPLOYMENT_TARGET -fembed-bitcode"
export LDFLAGS="-isysroot $SDKPATH -arch $ARCH -Wl,-ios_version_min,$DEPLOYMENT_TARGET -lbz2"

#        export XCRUN_SDK=`echo $PLATFORM | tr '[:upper:]' '[:lower:]'`
#        export CC="xcrun -sdk $XCRUN_SDK clang"

# force "configure" to use "gas-preprocessor.pl" (FFmpeg 3.3)
if [ "$ARCH" = "arm64" ]
then
export AS="gas-preprocessor.pl -arch aarch64 -- $CC"
else
export AS="$CC"
fi

export CXXFLAGS="$CFLAGS"

TARGET="$ARCH-darwin"
#        CFLAGS="$CFLAGS -target $TARGET"

#        if [ "$ARCH" = "arm" ]
#        then
#            find . -name Makefile -print0 | xargs -0 sed -i "s/arm-apple-darwin/arm64-apple-darwin/g"
#        fi


TMPDIR=${TMPDIR/%\/} $CWD/$SOURCE/configure \
$CONFIGURE_FLAGS \
--host="arm-apple-darwin" \
--prefix="$THIN/$ARCH" \
|| exit 1

#        exit 0

make -j3 install || exit 1
cd $CWD
done
fi

if [ "$LIPO" ]
then
echo "building fat binaries..."
mkdir -p $FAT/lib
set - $ARCHS
CWD=`pwd`
cd $THIN/$1/lib
for LIB in *.a
do
cd $CWD
echo lipo -create `find $THIN -name $LIB` -output $FAT/lib/$LIB 1>&2
lipo -create `find $THIN -name $LIB` -output $FAT/lib/$LIB || exit 1
done

cd $CWD
cp -rf $THIN/$1/include $FAT
fi

echo Done

