#!/bin/sh

set -e
set -o pipefail

source config.sh

config_for_maccatalyst

CWD=$(pwd)
LOG="${CWD}/${BUILD_DIR}/${BUILD_EXT}/build.log"
FAT="${BUILD_DIR}/${BUILD_EXT}/lib"
DEPS=(
#    aom
#    zvbi
#    freetype
#    harfbuzz
#    fribidi
#    libass
#    openssl
#    ffmpeg
#    mpv
)

ARCHS=(
    arm64
    x86_64
)

LIPO=y
XCFRAMEWORK=

echo "Starting Build $(date)" | tee ${LOG}

for DEP in ${DEPS[@]}
do
    cd ${CWD}

    SCRIPT_PATH="scripts/build-${DEP}.sh"
    for ARCH in ${ARCHS[@]}
    do
        echo "Building library ${DEP} for ${ARCH}" | tee -a ${LOG}
        
        config_for_maccatalyst $ARCH
        ${SCRIPT_PATH} $ARCH 2>&1 | tee -a ${LOG}
        [ "$?" != 0 ] && exit $?
    done

done

# Lipo

if [ "$LIPO" ]
then
    echo "Building fat libraries..." | tee -a ${LOG}

    if [ ! -r $FAT ]
    then
        mkdir $FAT
    fi

    arch_0=${ARCHS[0]}

    for lib in $(ls ${BUILD_DIR}/${BUILD_EXT}/${arch_0}/lib/*.a)
    do

        lipo_arguments=""
        lib_name=$(basename $lib)
        for ARCH in ${ARCHS[@]}
        do
            lipo_arguments="${lipo_arguments} ${BUILD_DIR}/${BUILD_EXT}/${ARCH}/lib/${lib_name}"
        done
        
        lipo -create \
            $lipo_arguments \
            -output "${FAT}/${lib_name}"
        
    done
fi

echo "Done"
