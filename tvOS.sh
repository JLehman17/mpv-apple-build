#!/bin/sh

set -e

source config.sh

CWD=$(pwd)
LOG="${CWD}/${BUILD_DIR}/${BUILD_EXT}/build.log"
DEPS=(
#    aom
#    zvbi
    harfbuzz
#    freetype
#    firbidi
#    libass
#    ffmpeg
#    mpv
)

for DEP in ${DEPS[@]}; do

    cd ${CWD}

    SCRIPT_PATH="scripts/tvOS/build-${DEP}-tvOS.sh"
    echo "Building library ${DEP}" | tee ${LOG}
    ${SCRIPT_PATH} 2>&1 | tee ${LOG}

done
