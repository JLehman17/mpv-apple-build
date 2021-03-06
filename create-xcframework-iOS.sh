#!/bin/sh

source config.sh

OUTPUT="${ROOT_DIR}/output"

PLATFORMS=(
    ios/arm64
    ios/x86_64
    maccatalyst/x86_64
)

if [ -r $OUTPUT ]
then
    rm -r $OUTPUT
fi
mkdir $OUTPUT

platform_0=${PLATFORMS[0]}
for lib in $(ls ${BUILD_DIR}/${platform_0}/lib/*.a)
do

    framework_arguments=""
    filename=$(basename $lib)
    lib_name="${filename%.*}"
    for platform in ${PLATFORMS[@]}
    do
        framework_arguments="$framework_arguments -library ${BUILD_DIR}/${platform}/lib/${filename}"
    done
    
    echo "Creating xcframwork for ${lib}"
    xcodebuild -create-xcframework \
        $framework_arguments \
        -output "${OUTPUT}/${lib_name}.xcframework"
done
