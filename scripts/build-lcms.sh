#!/bin/sh

ARCH=$1

VERSION="2.16"
SOURCE="src/lcms-$VERSION"

BUILD_OUT="${ROOT_DIR}/${BUILD_DIR}/${BUILD_EXT}/${ARCH}/scratch/lcms"
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

PATCHES=$ROOT_DIR/patches

function main() {

    if [ ! -r $SOURCE ]
    then
        echo 'Little CMS source not found. Trying to download...'

        mkdir -p $SOURCE &&
        curl -L https://github.com/mm2/Little-CMS/releases/download/lcms"${VERSION}"/lcms2-"${VERSION}".tar.gz |
            tar xj -C $SOURCE --strip-components 1 || exit 1
        
        cd $ROOT_DIR
    fi

    CWD=`pwd`
    echo "building..."
    mkdir -p "$PREFIX"
    cd "$SOURCE"

    crossfile="${ROOT_DIR}/tools/meson/${BUILD_EXT}_cross_${ARCH}.txt"

    meson setup "${BUILD_OUT}" \
        --prefix "${PREFIX}" \
        --includedir "$CWD/$BUILD_DIR/$BUILD_EXT/$ARCH/include" \
        --buildtype release \
        --cross-file="${crossfile}" \
        -Dc_args="${CFLAGS}" \
        -Dcpp_args="${CFLAGS}" \
        -Dobjc_args="${CFLAGS}" \
        -Dobjcpp_args="${CFLAGS}" \
        -Ddefault_library=static \
        || exit 1
        
    meson configure "${BUILD_OUT}"
    meson compile -C "${BUILD_OUT}"
    meson install -C "${BUILD_OUT}"

    echo Done
}

main "$@"
