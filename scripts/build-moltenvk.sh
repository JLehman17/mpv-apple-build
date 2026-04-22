#!/bin/sh

ARCH=$1

SOURCE="src/moltenVK-$MOLTENVK_VERSION-$BUILD_EXT"

BUILD_OUT="${ROOT_DIR}/${BUILD_DIR}/${BUILD_EXT}/${ARCH}/scratch/moltenVK"
PREFIX="${ROOT_DIR}/${BUILD_DIR}/${BUILD_EXT}/${ARCH}"

platform="$BUILD_EXT"
if [ "$BUILD_EXT" == "tvos" ]
then
    platform="tvos"
elif [ "$BUILD_EXT" == "maccatalyst" ]
then
    platform="maccat"
fi

unset SDKROOT
unset CC
unset CXX
unset DEVELOPER_DIR

if [ ! -r $SOURCE ]
then
    echo 'MoltenVK source not found. Trying to download...'

    mkdir -p $SOURCE && curl -L "https://github.com/KhronosGroup/MoltenVK/archive/v${MOLTENVK_VERSION}.tar.gz" |
        tar xj -C $SOURCE --strip-components 1 || exit 1
        
    cd $ROOT_DIR/$SOURCE
    ./fetchDependencies "--${platform}"
fi

cd $ROOT_DIR/$SOURCE
make clean
make "${platform}" || exit 1

# Copy output to our build directory
cp Package/Release/MoltenVK/static/MoltenVK.xcframework/*/*.a "$PREFIX/lib/libMoltenVK.a"
cp External/build/Release/glslang.xcframework/*/*.a "$PREFIX/lib/libglslang.a"
cp External/build/Release/SPIRVCross.xcframework/*/*.a "$PREFIX/lib/libSPIRVCross.a"
cp External/build/Release/SPIRVTools.xcframework/*/*.a "$PREFIX/lib/libSPIRVTools.a"
cp -R Package/Release/MoltenVK/include/ "$PREFIX/include/"

echo Done
