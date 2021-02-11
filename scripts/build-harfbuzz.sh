#!/bin/sh

ARCH=$1

HARFBUZZ_VERSION="2.7.2"
SOURCE="src/harfbuzz-$HARFBUZZ_VERSION"
SCRATCH="$BUILD_DIR/$BUILD_EXT/$ARCH/scratch/harfbuzz"
BUILD_OUT=$SCRATCH/"build"
PREFIX=`pwd`/$BUILD_OUT

root=$(pwd)

if [ ! -r $SOURCE ]
then
    echo "harfbuzz source not found. Attempting to download..."
    cd src
    curl -L "https://www.freedesktop.org/software/harfbuzz/release/harfbuzz-$HARFBUZZ_VERSION.tar.bz2" | tar -xj || exit 1
    
#        mkdir $SOURCE
#        cd $SOURCE
#        wget https://github.com/harfbuzz/harfbuzz/releases/download/$HARFBUZZ_VERSION/harfbuzz-$HARFBUZZ_VERSION.tar.xz -O - | \
#            tar -xJ --strip-components=1

    cd $root
fi

CWD=`pwd`
echo "building... $ARCH"
mkdir -p "$BUILD_OUT"
cd "$BUILD_OUT"
cd $SOURCE

#if [ "$ARCH" = "i386" -o "$ARCH" = "x86_64" ]
#then
#    PLATFORM="iphonesimulator"
#else
#    PLATFORM="iphoneos"
#fi
#
#XCRUN_SDK=`echo $PLATFORM | tr '[:upper:]' '[:lower:]'`
#SYSROOT=$(xcrun --sdk $XCRUN_SDK --show-sdk-path)
#CC="xcrun -sdk $XCRUN_SDK clang -isysroot=$SYSROOT"
#CXX="xcrun -sdk $XCRUN_SDK clang++ -isysroot=$SYSROOT"
#CPP="$CC -E"
#AR=$(xcrun -sdk $XCRUN_SDK -find ar)
#
#SDKPATH="$(xcodebuild -sdk $PLATFORM -version Path)"
#CFLAGS="-isysroot $SDKPATH -arch $ARCH -mios-version-min=$DEPLOYMENT_TARGET_IOS -arch $ARCH \
#                -I${CWD}/${BUILD_DIR}/${BUILD_EXT}/${ARCH}/include"
#LDFLAGS="-isysroot $SDKPATH -arch $ARCH -mios-version-min=$DEPLOYMENT_TARGET_IOS -arch $ARCH \
#                -L${CWD}/${BUILD_DIR}/${BUILD_EXT}/${ARCH}/lib"
#
## Generate toolchain description
#user_config="ios_cross_${ARCH}.txt"
#cat << EOF > $user_config
#[binaries]
#c     = "clang"
#cpp   = "clang++"
#ar    = "${AR}"
#pkgconfig = "pkg-config"
#
#[properties]
#needs_exe_wrapper = true
#root = "${SYSROOT}"
#has_function_printf = true
#has_function_hfkerhisadf = false
#c_args = ['-DCROSS=1']
#
#[host_machine]
#system = 'darwin'
#cpu_family = 'arm'
#cpu = 'arm64'
#endian = 'little'
#
#EOF
#
#unset CC CXX CPP AR CFLAGS LDFLAGS CPPFLAGS CXXFLAGS PKG_CONFIG PKG_CONFIG_PATH # meson wants these unset
#
#meson _build$ARCH \
#    --buildtype release \
#    --cross-file="${user_config}" \
#    -Ddefault_library=static \
#    -Dtests=disabled
#
#DESTDIR="$PREFIX" ninja -C _build$ARCH install
#
#exit 0



config_guess=$root/$SOURCE/config.guess
build=$($config_guess)

if [ "$ARCH" = "arm64" ]
then
    host="arm-apple-darwin"
else
    host="x86_64-apple-darwin"
fi

CONFIGURE_FLAGS=" \
--disable-shared \
--enable-static \
--disable-gtk-doc-html \
--with-cairo=no \
--with-freetype=yes \
--with-icu=no \
--with-glib=no \
--with-fontconfig=no \
--with-coretext=no \
--build=${build} \
--host=${host} \
"

$CWD/$SOURCE/configure $CONFIGURE_FLAGS \
     --prefix="$PREFIX" \
     --libdir=$CWD/$BUILD_DIR/$BUILD_EXT/$ARCH/lib \
     --includedir=$CWD/$BUILD_DIR/$BUILD_EXT/$ARCH/include \
 || exit 1

make -j4 install || exit 1


