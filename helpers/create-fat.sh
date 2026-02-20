#!/bin/sh

source config.sh

set -e

usage() {
    echo "Supply the path to a directory that contains a subdirectory for each arch"
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

echo "Building fat libraries..."

# Get list of arch directories, ignoring .DS_Store
ARCH_DIRS=()
for d in "$dir"/*; do
    if [ -d "$d" ] && [ "$(basename "$d")" != ".DS_Store" ]; then
        ARCH_DIRS+=("$d")
    fi
done

# Get list of libraries from first arch directory
LIBS=()
for f in "${ARCH_DIRS[0]}"/*; do
    if [ -f "$f" ] && [ "$(basename "$f")" != ".DS_Store" ]; then
        LIBS+=("$(basename "$f")")
    fi
done

# Output directory for fat libs
FAT_DIR="$dir/fat"
mkdir -p "$FAT_DIR"

# Build fat libraries
for lib in "${LIBS[@]}"; do
    echo "Building fat library for $lib..."
    LIPO_ARGS=()
    for arch_dir in "${ARCH_DIRS[@]}"; do
        thin="$arch_dir/$lib"
        if [ -f "$thin" ]; then
            LIPO_ARGS+=("$thin")
        fi
    done
    lipo -create "${LIPO_ARGS[@]}" -output "$FAT_DIR/$lib"
done

echo "All fat libraries created in $FAT_DIR"
