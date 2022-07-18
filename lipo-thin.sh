#!/bin/sh

set -e

CWD=`pwd`
LIBDIR="$CWD/build/release/tvos/lib"

ARCHS="arm64 x86_64"
LIBS="libass.a libavcodec.a libavdevice.a libavfilter.a libavformat.a libavresample.a libavutil.a libfreetype.a libfribidi.a libharfbuzz.a libmpv.a libpostproc.a libswresample.a libswscale.a libzvbi.a"

cd $LIBDIR

for ARCH in $ARCHS
do

    mkdir $ARCH
    for LIB in $LIBS
    do
        lipo ./$LIB -thin $ARCH -o $ARCH/$LIB
    done
    

done
