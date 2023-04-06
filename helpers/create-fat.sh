#!/bin/sh

CWD=`pwd`
BUILD="$CWD/build/release/libs-tvOS"
INCLUDE_DIR="$CWD/build/release/libs-tvOS/arm64/include"
ARM64_DIR="$CWD/build/release/libs-tvOS/arm64/"
X86_64_DIR="$CWD/build/release/libs-tvOS/x86_64/"

FFMPEG_LIBS=(
    libavcodec.a
    libavdevice.a
    libavfilter.a
    libavformat.a
    libavutil.a
    libpostproc.a
    libswresample.a
    libswscale.a
)

OTHER_LIBS=(
#    libass.a
#    libfreetype.a
#    libfribidi.a
#    libharfbuzz.a
#    libmpv.a
#    libzvbi.a
    libaom.a
)

LIBS=("${FFMPEG_LIBS[@]}" "${OTHER_LIBS[@]}")

set -e

for LIB in ${LIBS[@]}
do
    lipo -create $(find $BUILD/thin -name $LIB) -output $BUILD/lib/$LIB
done
