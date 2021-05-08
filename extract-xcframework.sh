#!/bin/sh

source config.sh

OUTPUT="${ROOT_DIR}/extracted"

function usage() {
    echo "Supply the path to a directory that contains xcframeworks"
    exit 1
}

if [ $# != 1 ]; then
    usage
fi

dir=$1
if [ ! -d $dir ]; then
    echo "Invalid path ${dir}"
    usage
fi

if [ ! -d $OUTPUT ]
then
    mkdir $OUTPUT
fi

for framework in $(ls -d ${dir}/*.xcframework)
do
    framework_name=$(basename $framework .xcframework)
    echo "Extracting ${framework_name}"
    for arch in $(ls -d $framework/*/)
    do
        arch_name=$(basename $arch)
        out=$OUTPUT/$arch_name
        if [ ! -d $out ]
        then
            mkdir $out
        fi
        cp -r $arch/* $out
#        echo $arch_name
    done
    
#    framework_arguments=""
#    filename=$(basename $lib)
#    lib_name="${filename%.*}"
#    for platform in ${PLATFORMS[@]}
#    do
#        framework_arguments="$framework_arguments -library ${BUILD_DIR}/${platform}/lib/${filename}"
#    done
#
#    echo "Creating xcframwork for ${lib}"
#    xcodebuild -create-xcframework \
#        $framework_arguments \
#        -output "${OUTPUT}/${lib_name}.xcframework"
done
