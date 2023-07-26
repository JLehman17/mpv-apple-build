#!/bin/sh

source config.sh

OUTPUT="${ROOT_DIR}/xcframeworks"

function usage() {
    echo "Creates an xcframework from a directory containing thin libraries. Supply the path to a directory containing thin libraries."
    exit 1
}

if [ $# != 1 ]; then
    usage
fi

src=$1
if [ ! -d $src ]; then
    echo "Invalid path ${dir}"
    usage
fi

if [ ! -d $OUTPUT ]
then
    mkdir $OUTPUT
fi

archs=$(ls ${src})
arch_0=($archs)

for lib in $(ls ${src}/${arch_0}/*.a)
do
    framework_arguments=""
    lib_name=$(basename $lib)
    for arch in ${archs[@]}
    do
        framework_arguments="$framework_arguments -library ${src}/${arch}/${lib_name}"
    done
    
    echo "Creating xcframework for ${lib_name}"
    xcodebuild -create-xcframework \
        $framework_arguments \
        -output "${OUTPUT}/${lib_name%.*}.xcframework"
done
