#!/bin/sh

set -e

CWD=`pwd`
INCLUDE_DIR="$CWD/build/release/maccatalyst/include"
MAC_DIR="$CWD/build/release/maccatalyst/lib/"
ARM64_DIR="$CWD/build/release/libs-iOS/arm64/"
X86_64_DIR="$CWD/build/release/libs-iOS/x86_64/"

FFMPEG_DIR="$CWD/build/release/ffmpeg-iOS/thin"
MPV_DIR="$CWD/build/release/mpv-iOS/thin"
FRAMEWORKS_DIR="/Users/josh/Projects/Emby/emby-ios/Frameworks/"

FFMPEG_LIBS=(
    libavcodec
    libavdevice
    libavfilter
    libavformat
    libavutil
    libpostproc
    libswresample
    libswscale
)

OTHER_LIBS=(
#    libass
#    libfreetype
#    libfribidi
#    libharfbuzz
#    libmpv
#    libzvbi
)

#LIBS=("${FFMPEG_LIBS[@]}" "${OTHER_LIBS[@]}")

TARGETS=(
#    ios-arm64
    ios-x86_64-simulator
#    ios-x86_64-maccatalyst
)

#ARCH="arm64"
ARCH="x86_64"

for TARGET in ${TARGETS[@]}
do

    for LIB in ${FFMPEG_LIBS[@]}
    do
        cp "$FFMPEG_DIR/$ARCH/lib/$LIB.a" "$FRAMEWORKS_DIR/$LIB.xcframework/$TARGET"
    done

    for LIB in ${OTHER_LIBS[@]}
    do
        cp "$MPV_DIR/$ARCH/lib/$LIB.a" "$FRAMEWORKS_DIR/$LIB.xcframework/$TARGET"
    done

done
