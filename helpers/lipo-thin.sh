#!/bin/sh

set -e

usage() {
    echo "Supply the path to a directory that contains fat binaries"
    exit 1
}

if [ $# != 1 ]; then
    usage
fi

dir="$1"

if [ ! -d "$dir" ]; then
    echo "Invalid path ${dir}"
    usage
fi

# Get first regular file that is not .DS_Store
FIRST_FILE=$(find "$dir" -maxdepth 1 -type f ! -name ".DS_Store" | head -n 1)

if [ -z "$FIRST_FILE" ]; then
    echo "No valid binary files found in $dir"
    exit 1
fi

# Extract architectures from first file
ARCHS=$(lipo -info "$FIRST_FILE" | sed -E 's/.*are: //; s/.*architecture: //')

# Get all regular files except .DS_Store
LIBS=$(find "$dir" -maxdepth 1 -type f ! -name ".DS_Store")

for ARCH in $ARCHS
do
    mkdir -p "$dir/$ARCH"

    for LIB in $LIBS
    do
        BASENAME=$(basename "$LIB")
        lipo "$LIB" -thin "$ARCH" -o "$dir/$ARCH/$BASENAME"
    done
done

echo "Done."
