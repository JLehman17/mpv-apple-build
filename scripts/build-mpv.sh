#!/bin/sh

ARCH=$1

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

function main() {

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
        
        if [ ! "$MPV_VERSION" = "master" ]
        then
            # If using mpv < 0.37.0
            if version_lt "$MPV_VERSION" "0.37.0";
            then
                echo "$MPV_VERSION is lower than 0.37.0. Running bootstrap..."
                ./bootstrap.py
            fi
        fi

        mkdir -p subprojects
        git clone https://code.videolan.org/videolan/libplacebo.git --depth=1 --recursive subprojects/libplacebo
        
        cd $ROOT_DIR
    fi

    CWD=`pwd`
    echo "building..."
    mkdir -p "$PREFIX"
    cd "$SOURCE"

    if [ "$VULKAN_TEST" ]
    then
        echo "MoltenVK Build"
        build_with_waf
        echo Done
        exit 0
    fi
    
    if [ ! "$MPV_VERSION" = "master" ]
    then
        # If using mpv < 0.37.0
        if version_lt "$MPV_VERSION" "0.37.0";
        then
            echo "Building with waf..."
            build_with_waf
            echo Done
            exit 0
        fi
    fi

    crossfile="${ROOT_DIR}/tools/meson/${BUILD_EXT}_cross_${ARCH}.txt"

    # It seems that ios-gl and videotoolbox-gl are mutually exclusive
    # See: https://github.com/mpv-player/mpv/blob/release/0.38/video/out/hwdec/hwdec_vt.h#L47
    if [ "$BUILD_EXT" == "maccatalyst" ]
    then
        gl_arg="-Dplain-gl=enabled"
    else
        gl_arg="-Dios-gl=enabled"
    fi
    
    videotoolbox_enable=""
    if [ "$BUILD_EXT" == "tvos" -o "$BUILD_EXT" == "ios" ]
    then
        videotoolbox_enable="-Dvideotoolbox-gl=disabled"
    fi

    meson setup --reconfigure "${BUILD_OUT}" \
        --prefix "${PREFIX}" \
        --includedir "$CWD/$BUILD_DIR/$BUILD_EXT/$ARCH/include" \
        --buildtype release \
        --cross-file="${crossfile}" \
        -Dc_args="${CFLAGS}" \
        -Dcpp_args="${CFLAGS}" \
        -Dobjc_args="${CFLAGS}" \
        -Dobjcpp_args="${CFLAGS}" \
        -Ddefault_library=static \
        -Dswift-build=disabled \
        -Dlibmpv=true \
        "${gl_arg}" \
        "${videotoolbox_enable}" \
        -Dcocoa=disabled \
        -Dcoreaudio=disabled \
        -Dmacos-cocoa-cb=disabled \
        -Dmacos-media-player=disabled \
        -Dmacos-touchbar=disabled \
        -Dmanpage-build=disabled \
        -Dcplayer=false \
        -Dlua=disabled \
        -Djavascript=disabled \
        -Drubberband=disabled \
        -Dlibbluray=disabled \
        -Dvapoursynth=disabled \
        -Duchardet=disabled \
        -Djpeg=disabled \
        -Dzimg=disabled \
        -Dlcms2=enabled \
        -Dmoltenvk=enabled \
        || exit 1
        
    #    -Daudiounit=enabled \
    #    -Davfoundation=disabled \
    #    -Dcoreaudio=disabled \
    #    -Dcocoa=disabled \
        
    meson configure "${BUILD_OUT}"
    meson compile -C "${BUILD_OUT}"
    meson install -C "${BUILD_OUT}"

    echo Done
}


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
    --disable-vaapi \
    --disable-wayland \
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
        CONFIGURE_FLAGS="$CONFIGURE_FLAGS --disable-libass --enable-audioengine"
    else
        CONFIGURE_FLAGS="$CONFIGURE_FLAGS --enable-vulkan"
    fi
    
    if [ "$VULKAN_TEST" ]
    then
        CONFIGURE_FLAGS="$CONFIGURE_FLAGS --enable-moltenvk --enable-libplacebo"
    fi
    
    if [ "$BUILD_EXT" == "tvos" ]
    then
        CONFIGURE_FLAGS="$CONFIGURE_FLAGS --enable-tvos"
    fi

    echo "Configuring with options $CONFIGURE_FLAGS"

    python3.10 ./waf configure $CONFIGURE_FLAGS \
        --prefix="$PREFIX" \
        --out="$BUILD_OUT" \
        --libdir="$CWD/$BUILD_DIR/$BUILD_EXT/$ARCH/lib" \
        --includedir="$CWD/$BUILD_DIR/$BUILD_EXT/$ARCH/include" \
    || exit 1
    python3.10 ./waf clean
    python3.10 ./waf build -j4 || exit 1
    python3.10 ./waf install || exit 1
}

function version_lt() {
    local IFS=.
    local i ver1=($1) ver2=($2)

    # pad shorter version with zeros
    for ((i=${#ver1[@]}; i<${#ver2[@]}; i++)); do
        ver1[i]=0
    done
    for ((i=${#ver2[@]}; i<${#ver1[@]}; i++)); do
        ver2[i]=0
    done

    for ((i=0; i<${#ver1[@]}; i++)); do
        if ((10#${ver1[i]} < 10#${ver2[i]})); then
            return 0
        fi
        if ((10#${ver1[i]} > 10#${ver2[i]})); then
            return 1
        fi
    done

    return 1
}

main "$@"
