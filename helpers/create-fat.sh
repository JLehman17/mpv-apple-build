#!/bin/sh

source config.sh

OUTPUT="${ROOT_DIR}/extracted-fat"

src="${ROOT_DIR}/extracted/"

echo "Building fat libraries..."

if [ ! -d $OUTPUT ]
then
    mkdir $OUTPUT
fi

archs=$(ls ${src})
arch_0=($archs)

for lib in $(ls ${src}/${arch_0}/*.a)
do

    lipo_arguments=""
    lib_name=$(basename $lib)
    for arch in ${archs[@]}
    do
        lipo_arguments="${lipo_arguments} ${src}/${arch}/${lib_name}"
    done

    lipo -create \
        ${lipo_arguments} \
        -output "${OUTPUT}/${lib_name}"
    
done
