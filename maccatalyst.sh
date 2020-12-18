#!/bin/sh

set -e

source config.sh

config_for_maccatalyst

CWD=$(pwd)
LOG="${CWD}/${BUILD_DIR}/${BUILD_EXT}/build.log"
DEPS=(
    aom
    zvbi
    freetype
    harfbuzz
    fribidi
    libass
    ffmpeg
    mpv
)

ARCHS=(
    x86_64
    arm64
)

echo "Starting Build $(date)" | tee ${LOG}
for DEP in ${DEPS[@]}
do
    cd ${CWD}

    SCRIPT_PATH="scripts/${BUILD_EXT}/build-${DEP}-${BUILD_EXT}.sh"
    for ARCH in ${ARCHS[@]}
    do
        echo "Building library ${DEP} for ${ARCH}" | tee -a ${LOG}
        
        config_for_maccatalyst $ARCH
        ${SCRIPT_PATH} $ARCH 2>&1 | tee -a ${LOG}
    done

done
