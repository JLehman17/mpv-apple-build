#!/bin/sh

CWD=`pwd`
INCLUDE_DIR="$CWD/build/release/macOS/include"
MAC_DIR="$CWD/build/release/macOS/lib/"
ARM64_DIR="$CWD/build/release/libs-iOS/arm64/"
X86_64_DIR="$CWD/build/release/libs-iOS/x86_64/"

LIBS=(
    libass.a
    libavcodec.a
    libavdevice.a
    libavfilter.a
    libavformat.a
    libavutil.a
    libfreetype.a
    libfribidi.a
    libharfbuzz.a
    libmpv.a
    libpostproc.a
    libswresample.a
    libswscale.a
    libzvbi.a
)

rm -R "./output"

set -e

for LIB in ${LIBS[@]}
do
    xcodebuild -create-xcframework \
                -library "$MAC_DIR/$LIB" \
                -library "$ARM64_DIR/$LIB" \
                -library "$X86_64_DIR/$LIB" \
                -output  "$CWD/output/$(basename $LIB .a).xcframework"
done
