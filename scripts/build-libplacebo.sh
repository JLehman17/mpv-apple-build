
#!/bin/sh

ARCH=$1

VERSION="6.338.2"
#VERSION="3.120.3" # needed for tmm1's moltenVK for iOS/tvOS
SOURCE="src/libplacebo-$VERSION"

BUILD_OUT="${ROOT_DIR}/${BUILD_DIR}/${BUILD_EXT}/${ARCH}/scratch/libplacebo"
PREFIX="${ROOT_DIR}/${BUILD_DIR}/${BUILD_EXT}/${ARCH}"


if [ ! -r $SOURCE ]
then
    echo "libplacebo source not found. Attempting to download..."
    cd src
#    curl -L "https://github.com/haasn/libplacebo/archive/v${VERSION}.tar.gz" | tar -xj || exit 1
    git clone https://github.com/haasn/libplacebo.git "libplacebo-${VERSION}"
    cd "libplacebo-${VERSION}"
    git checkout "v${VERSION}"
    git submodule update --init
    cd $ROOT_DIR
fi

CWD=`pwd`
echo "building..."
cd "${SOURCE}"

#unset CC CXX # meson wants these unset

crossfile="${ROOT_DIR}/tools/meson/${BUILD_EXT}_cross_${ARCH}.txt"
registry="${ROOT_DIR}/src/moltenVK-1.2.8-${BUILD_EXT}/External/Vulkan-Headers/registry/vk.xml"

#build="./build_${BUILD_EXT}"

#if [ -d $build ]
#then
#    echo "Removing old build directory"
#    rm -r $build
#fi

#meson setup --wipe $build
#meson configure --clearcache $build
#meson --reconfigure $build -Dvulkan-registry="${registry}"

#-Dname_include_path="${CWD}/${BUILD_DIR}/${BUILD_EXT}/${ARCH}/include/" \

#meson setup --wipe $build \
#    --cross-file="${crossfile}" \
#    --libdir="${ROOT_DIR}/${BUILD_DIR}/${BUILD_EXT}/${ARCH}/lib" \
#    || exit 1

meson setup --reconfigure "${BUILD_OUT}" \
    --prefix "$PREFIX" \
    --buildtype release \
    --cross-file="${crossfile}" \
    --libdir="${ROOT_DIR}/${BUILD_DIR}/${BUILD_EXT}/${ARCH}/lib" \
    --includedir="${ROOT_DIR}/${BUILD_DIR}/${BUILD_EXT}/${ARCH}/include" \
    -Dc_args="${CFLAGS}" \
    -Dcpp_args="${CFLAGS}" \
    -Dobjc_args="${CFLAGS}" \
    -Dobjcpp_args="${CFLAGS}" \
    -Dc_link_args="${LDFLAGS}" \
    -Dcpp_link_args="${LDFLAGS}" \
    -Ddefault_library=static \
    -Dprefer_static=true \
    -Dvulkan-registry="${registry}" \
    -Dtests=false \
    -Ddemos=false \
    -Dvulkan=enabled \
    -Dglslang=enabled \
    -Dshaderc=disabled \
    || exit 1

#ninja -C $BUILD_OUT install || exit 1

meson configure "${BUILD_OUT}"
meson compile -C "${BUILD_OUT}"
meson install -C "${BUILD_OUT}"

echo Done
