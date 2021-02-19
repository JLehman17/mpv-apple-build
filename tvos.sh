#!/bin/sh

set -e
set -o pipefail

source config.sh

config_for_tvos

CWD=$(pwd)
LOG="${CWD}/${BUILD_DIR}/${BUILD_EXT}/build.log"
FAT="${BUILD_DIR}/${BUILD_EXT}/lib"
DEPS=(
#    aom
#    zvbi
#    freetype # Harfbuzz needs freetype.
#    harfbuzz
#    freetype # Build freetype again with harfbuzz support.
#    fribidi
#    libass
#    ffmpeg
#    mpv
)

ARCHS=(
    arm64
    x86_64
    arm64-simulator
)

echo "Starting Build $(date)" | tee ${LOG}

for DEP in ${DEPS[@]}
do
    cd ${CWD}

    SCRIPT_PATH="scripts/build-${DEP}.sh"
    for ARCH in ${ARCHS[@]}
    do
        echo "Building library ${DEP} for ${ARCH}" | tee -a ${LOG}
        
        config_for_tvos $ARCH
        ${SCRIPT_PATH} $ARCH 2>&1 | tee -a ${LOG}
        [ "$?" != 0 ] && exit $?
    done

done

# Build xcframework

OUTPUT="${BUILD_DIR}/${BUILD_EXT}/xcframeworks"

if [ -r $OUTPUT ]
then
    rm -r $OUTPUT
fi
mkdir $OUTPUT

LIPO_ARCHS=(
    arm64-simulator
    x86_64
)

arch_0=${LIPO_ARCHS[0]}
[ ! -d "${BUILD_DIR}/${BUILD_EXT}/simulator/" ] && mkdir "${BUILD_DIR}/${BUILD_EXT}/simulator/"

for lib in $(ls ${BUILD_DIR}/${BUILD_EXT}/${arch_0}/lib/*.a)
do

    lipo_arguments=""
    lib_name=$(basename $lib)
    for ARCH in ${LIPO_ARCHS[@]}
    do
        lipo_arguments="${lipo_arguments} ${BUILD_DIR}/${BUILD_EXT}/${ARCH}/lib/${lib_name}"
    done
    
    lipo -create \
        $lipo_arguments \
        -output "${BUILD_DIR}/${BUILD_EXT}/simulator/lib/${lib_name}"
    
done

paltforms=(
    simulator
    arm64
)

for lib in $(ls ${BUILD_DIR}/${BUILD_EXT}/${paltforms[0]}/lib/*.a)
do

    framework_arguments=""
    filename=$(basename $lib)
    lib_name="${filename%.*}"
    for arch in ${paltforms[@]}
    do
        framework_arguments="$framework_arguments -library ${BUILD_DIR}/${BUILD_EXT}/${arch}/lib/${filename}"
    done
    
    echo "Creating xcframwork for ${lib}"
    xcodebuild -create-xcframework \
        $framework_arguments \
        -output "${OUTPUT}/${lib_name}.xcframework"
done

echo "Done"
