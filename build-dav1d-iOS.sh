#!/bin/sh


ARCHS="arm64 x86_64"
DEPLOYMENT_TARGET="11.0.0"

CWD=`pwd`
DAV1D_VERSION="0.7.1"
SOURCE="dav1d-${DAV1D_VERSION}"


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
    if ! command -v meson &> /dev/null
    then
        python3 -m pip install meson==0.53.1
    fi
    
    if ! command -v ninja &> /dev/null
    then
        python3 -m pip install ninja
    fi

    if [ ! -r $SOURCE ]
    then
        echo 'dav1d source not found. Trying to download...'
        curl -L https://github.com/videolan/dav1d/archive/$DAV1D_VERSION.tar.gz | tar xj || exit 1
    fi
}

function ensureCrossFile() {
    
    arch=$1
    cross=package/crossfiles/$arch-iOS.meson
    
    if [ "$arch" = "x86_64" ]
    then
        platform="iphonesimulator"
        family=$arch
    else
        platform="iphoneos"
        family=arm
    fi
    
    xcrun_sdk=`echo $platform | tr '[:upper:]' '[:lower:]'`
    sdkroot=$(xcrun --sdk $xcrun_sdk --show-sdk-path)
    cc=$(xcrun -sdk $xcrun_sdk -find clang)
    cxx=$(xcrun -sdk $xcrun_sdk -find clang++)
    
    export SDKROOT=$sdkroot
    export CC="env -u SDKROOT clang"
    
    
    export PATH="/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/:$PATH"
    export SDKPATH="$(xcodebuild -sdk $platform -version Path)"
#    export CFLAGS="-isysroot $SDKPATH -arch $arch"
#    export LDFLAGS="-isysroot $SDKPATH -arch $arch"
    
    
    sysroot="'$sdkroot'"
    version_target="'-miphoneos-version-min=${DEPLOYMENT_TARGET}'"

#    if [ ! -f $cross ]; then
        echo [binaries] > $cross
#        echo c = "'$cc'" >> $cross
#        echo cpp = "'$cxx'" >> $cross
        echo c = "'clang'" >> $cross
        echo cpp = "'clang++'" >> $cross
        echo ar = "'ar'" >> $cross
        echo strip = "'strip'" >> $cross
#        echo pkgconfig = "'pkg-config'" >> $cross
#        echo windres = 'arm-linux-androideabi-windres' >> $cross

#        echo [built-in options] >> $cross
#        echo c_args = ["'-arch'", "'$arch'", $version_target, "'-isysroot'", "'$SDKPATH'"] >> $cross
#        echo cpp_args = ["'-arch'", "'$arch'", $version_target, "'-isysroot'", "'$SDKPATH'"] >> $cross
#        echo c_link_args = ["'-arch'", "'$arch'", $version_target, "'-isysroot'", "'$SDKPATH'"] >> $cross
#        echo cpp_link_args = ["'-arch'", "'$arch'", $version_target, "'-isysroot'", "'$SDKPATH'"] >> $cross
        
        echo [properties] >> $cross
#        echo c_args = ["'-arch'", "'$arch'"] >> $cross
        echo c_args = ["'-arch'", "'$arch'", $version_target, "'-isysroot'", "'$SDKPATH'", "'-fembed-bitcode'"] >> $cross
        echo cpp_args = ["'-arch'", "'$arch'", $version_target, "'-isysroot'", "'$SDKPATH'"] >> $cross
        echo c_link_args = ["'-arch'", "'$arch'", $version_target, "'-isysroot'", "'$SDKPATH'"] >> $cross
        echo cpp_link_args = ["'-arch'", "'$arch'", $version_target, "'-isysroot'", "'$SDKPATH'"] >> $cross
        echo needs_exe_wrapper = true >> $cross
#        echo sys_root = "'$SDKPATH'" >> $cross
#        echo root = $sysroot >> $cross
#        echo root = "'/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer'" >> $cross
#        echo has_function_printf = true >> $cross
#        echo has_function_hfkerhisadf = false >> $cross
#        echo pkg_config_libdir = '/some/path/lib/pkgconfig' >> $cross
        
        echo [host_machine] >> $cross
        echo system = "'darwin'" >> $cross
        echo cpu_family = "'$family'" >> $cross
        echo endian = "'little'" >> $cross
        echo cpu = "'$arch'" >> $cross
#    fi
}

downloadDeps

cd ./$SOURCE/

cwd=$(pwd)
for ARCH in $ARCHS
do
    echo "Building $ARCH..."
    
    cd $cwd
    ensureCrossFile $ARCH

#        export PKG_CONFIG_SYSROOT_DIR="$CWD/build/release/libs-iOS"
#        export PKG_CONFIG_LIBDIR="$PKG_CONFIG_SYSROOT_DIR/$ARCH/pkgconfig"

    build="${cwd}/build"
    scratch="${build}/scratch/${ARCH}"

#    rm -r $scratch
    meson $scratch \
    --cross-file="${cwd}/package/crossfiles/$arch-iOS.meson" \
    --default-library=static \
    --prefix=$build \
    --includedir="${build}/include" \
    --libdir="${build}/thin/${ARCH}"
    
    cd $scratch
    ninja install || exit 1
    cd ..

done

cd ./..

echo Done


