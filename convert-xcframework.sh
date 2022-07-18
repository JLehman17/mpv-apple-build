#!/bin/sh

set -e

source config.sh

function usage() {
    echo "Supply the path to a directory that contains fat libraries"
    exit 1
}

function list_archs() {
    lipo -info $1 | sed -En -e 's/^(Non-|Architectures in the )fat file: .+( is architecture| are): (.*)$/\3/p'
}

if [ $# != 1 ]; then
    usage
fi

dir=$1
if [ ! -d $dir ]; then
    echo "Invalid path ${dir}"
    usage
fi

output="${dir}/xcframeworks"

if [ ! -d $output ]
then
    mkdir $output
fi

thin="${dir}/thin"

for lib in $(ls ${dir}/*.a)
do
    lib_name=$(basename $lib .a)
    echo "Converting ${lib_name}"
    for arch in $(list_archs $lib)
    do
        # Extract architectures
        thin_arch="${thin}/${lib_name}/${arch}"
        mkdir -p $thin_arch
        lipo -extract $arch $lib -o "${thin_arch}/${lib_name}.a"
    done
done

# watchOS archs arm64_32 and armv7k must be in the same library
for lib_name in $(ls "${thin}")
do
    if [ -d "${thin}/${lib_name}/arm64_32" ] && [ -d "${thin}/${lib_name}/armv7k" ]
    then
        thin_arch="${thin}/${lib_name}/armv7k_arm64_32"
        mkdir -p $thin_arch
        lipo -create "${thin}/${lib_name}/arm64_32/${lib_name}.a" "${thin}/${lib_name}/armv7k/${lib_name}.a" \
            -o "${thin}/${lib_name}/armv7k_arm64_32/${lib_name}.a"
        rm -r "${thin}/${lib_name}/arm64_32"
        rm -r "${thin}/${lib_name}/armv7k"
    fi
done
    
for lib_name in $(ls "${thin}")
do
    # Create .xcframework
    framework_arguments=""
    for arch in $(ls "${thin}/${lib_name}")
    do
        framework_arguments="$framework_arguments -library ${thin}/${lib_name}/${arch}/${lib_name}.a"
    done
    
    echo "Creating xcframework for ${lib_name}"
    xcodebuild -create-xcframework \
        $framework_arguments \
        -output "${output}/${lib_name}.xcframework"
done

rm -r "$thin"
