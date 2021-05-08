#!/bin/sh

ARCH=$1

VERSION="3.104.0"
SOURCE="src/libplacebo-$VERSION"

BUILD_OUT="$ROOT_DIR/$BUILD_DIR/$BUILD_EXT/$ARCH/scratch/libplacebo"
SCRATCH=$BUILD_OUT/"build"
PREFIX="$ROOT_DIR/$BUILD_DIR/$BUILD_EXT/$ARCH/lib"

if [ ! -r $SOURCE ]
then
    echo "libplacebo source not found. Attempting to download..."
    cd src
    curl -L "https://github.com/haasn/libplacebo/archive/v${VERSION}.tar.gz" | tar -xj || exit 1
    cd $ROOT_DIR
fi

cd $SOURCE

CWD=`pwd`
echo "building..."
mkdir -p "$SCRATCH"

unset CC CXX # meson wants these unset

registry="${ROOT_DIR}/src/moltenVK-1.1.2-maccatalyst/External/Vulkan-Headers/registry/vk.xml"

build="./build_${BUILD_EXT}"

meson configure --clearcache $build
meson --reconfigure $build -Dvulkan-registry="${registry}"

meson $build \
    --buildtype release \
    -Ddefault_library=static \
    -Dvulkan-registry="${registry}" \
    -Dtests=false

DESTDIR="$PREFIX" ninja -C $build install

echo Done
