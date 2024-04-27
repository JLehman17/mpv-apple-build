#!/bin/sh

ARCH=$1

#if [ "$BUILD_EXT" == "watchos" ]
#then
#    # 0.33.0 doesn't use posix-spawn which is prohibited on watchOS... Unfortuantely it also make libass a requirement.
#    MPV_VERSION="0.33.0"
#else
#    MPV_VERSION="0.32.0"
#fi
MPV_VERSION="0.38.0"
SOURCE="src/mpv-$MPV_VERSION"

BUILD_OUT="${ROOT_DIR}/${BUILD_DIR}/${BUILD_EXT}/${ARCH}/scratch/mpv"
PREFIX="${ROOT_DIR}/${BUILD_DIR}/${BUILD_EXT}/${ARCH}"

DEBUG=
while getopts d option
do
    case "${option}" in
        d) DEBUG="y"
#           BUILD_DIR="build/debug"
           shift;;
    esac
done

VULKAN_TEST=

PATCHES=$ROOT_DIR/patches

if [ "$VULKAN_TEST" ]
then
#    MPV_VERSION="vulkan"
    MPV_VERSION="moltenvk"
    SOURCE="src/mpv-$MPV_VERSION-$BUILD_EXT"
    if [ ! -r $SOURCE ]; then
    
        git clone "https://github.com/tmm1/mpv-player.git" $SOURCE
#        git clone "https://github.com/Akemi/mpv.git" $SOURCE
        cd $ROOT_DIR/$SOURCE
#        git checkout mac_vulkan
        git checkout moltenvk
        ./bootstrap.py
        cd $ROOT_DIR
    fi
elif [ ! -r $SOURCE ]
then
    echo 'mpv source not found. Trying to download...'

#    cd src
    if [ "$MPV_VERSION" = "master" ]
    then
        mpv_name="$MPV_VERSION"
    else
        mpv_name="v$MPV_VERSION"
    fi
    mkdir -p $SOURCE && curl -L https://github.com/mpv-player/mpv/archive/"$mpv_name".tar.gz |
        tar xj -C $SOURCE --strip-components 1 || exit 1

    cd $ROOT_DIR/$SOURCE
    
    if [ "$BUILD_EXT" == "tvos" ]
    then
        echo "Applying tvOS wscript_build patch..."
        cd $SOURCE
        patch="$PATCHES/tvos_wscript_build.py.patch"
        cp $patch ./ &&
        patch -p0 < "tvos_wscript_build.py.patch" && rm "./tvos_wscript_build.py.patch" || exit 1
    fi
    
    # If using mpv < 0.37.0
#    ./bootstrap.py
    # else
    mkdir -p subprojects
    git clone https://code.videolan.org/videolan/libplacebo.git --depth=1 --recursive subprojects/libplacebo
    
    cd $ROOT_DIR
fi

CWD=`pwd`
echo "building..."
mkdir -p "$PREFIX"
cd "$SOURCE"

crossfile="${ROOT_DIR}/tools/meson/${BUILD_EXT}_cross_${ARCH}.txt"

# It seems that ios-gl and videotoolbox-gl are mutually exclusive
# See: https://github.com/mpv-player/mpv/blob/release/0.38/video/out/hwdec/hwdec_vt.h#L47

meson setup --reconfigure "${BUILD_OUT}" \
    --prefix "${PREFIX}" \
    --buildtype release \
    --cross-file="${crossfile}" \
    -Ddefault_library=static \
    -Dswift-build=disabled \
    -Dlibmpv=true \
    -Dios-gl=enabled \
    -Dvideotoolbox-gl=disabled \
    -Dcplayer=false \
    -Dlua=disabled \
    -Djavascript=disabled \
    -Drubberband=disabled \
    -Dlibbluray=disabled \
    -Djpeg=disabled \
    -Dzimg=disabled \
    -Dlcms2=disabled \
    || exit 1
    
#    -Daudiounit=enabled \
#    -Davfoundation=disabled \
#    -Dcoreaudio=disabled \
    
meson configure "${BUILD_OUT}"
meson compile -C "${BUILD_OUT}"
meson install -C "${BUILD_OUT}"

echo Done



# Waf build system was removed in v0.37.0
function build_with_waf() {
    CONFIGURE_FLAGS=" \
    --disable-cplayer \
    --disable-lcms2 \
    --disable-lua \
    --disable-javascript \
    --disable-cuda-hwaccel \
    --enable-libmpv-static \
    --disable-uchardet \
    --enable-gl \
    --enable-lgpl \
    --disable-rubberband \
    --disable-libbluray \
    --disable-zimg \
    --disable-vapoursynth \
    --enable-moltenvk \
    --enable-libplacebo \
    --disable-vaapi \
    --disable-wayland \
    --enable-vulkan \
    --enable-tvos \
    "

    #--enable-avfoundation \

    if [ "$DEBUG" ]
    then
        CONFIGURE_FLAGS="$CONFIGURE_FLAGS --disable-optimize"
    else
        CONFIGURE_FLAGS="$CONFIGURE_FLAGS"
    fi

    if [ "$BUILD_EXT" == "watchos" ]
    then
        CONFIGURE_FLAGS="$CONFIGURE_FLAGS --disable-libass"
    fi

    echo "Configuring with options $CONFIGURE_FLAGS"

    python3 ./waf configure $CONFIGURE_FLAGS \
        --prefix="$PREFIX" \
        --out="$PREFIX" \
        --libdir="$CWD/$BUILD_DIR/$BUILD_EXT/$ARCH/lib" \
        --includedir="$CWD/$BUILD_DIR/$BUILD_EXT/$ARCH/include" \
    || exit 1
    #python3 ./waf clean
    python3 ./waf build -j4 || exit 1
    python3 ./waf install || exit 1
}
