#!/bin/sh


# directories
FF_VERSION="emby"
SOURCE="ffmpeg-4.1.3"

DEBUG=
BUILD_DIR="build/release"

while getopts d option
do
    case "${option}" in
        d) DEBUG="y"
           BUILD_DIR="build/debug"
           shift;;
    esac
done

COMPILE="y"
LIPO="y"
ARCHS="arm64 x86_64"

CWD=`pwd`
FAT=$BUILD_DIR/"ffmpeg-tvOS"
SCRATCH=$FAT/"scratch"
THIN=$CWD/$FAT/"thin"

PATCHES=$CWD/patches/ffmpeg

ZVBI=$CWD/zvbi-tvOS/fat

# absolute path to x264 library
#X264=`pwd`/fat-x264

#FDK_AAC=`pwd`/../fdk-aac-build-script-for-iOS/fdk-aac-ios


CONFIGURE_FLAGS=" \
--enable-cross-compile \
--disable-programs \
--disable-indev=avfoundation \
--disable-doc \
--disable-symver \
--enable-pic \
--disable-shared \
--enable-static \
--enable-gpl \
--enable-videotoolbox \
--disable-decoder=dca \
--disable-decoder=mlp \
--disable-decoder=truehd \
--enable-libaom
"

if [ "$DEBUG" ]
then
    CONFIGURE_FLAGS="$CONFIGURE_FLAGS --enable-debug --disable-stripping --disable-optimizations"
else
    CONFIGURE_FLAGS="$CONFIGURE_FLAGS --disable-debug --enable-stripping --enable-optimizations"
fi


if [ "$X264" ]
then
	CONFIGURE_FLAGS="$CONFIGURE_FLAGS --enable-libx264"
fi

if [ "$X265" ]
then
    CONFIGURE_FLAGS="$CONFIGURE_FLAGS --enable-libx256"
fi

if [ "$FDK_AAC" ]
then
	CONFIGURE_FLAGS="$CONFIGURE_FLAGS --enable-libfdk-aac --enable-nonfree"
fi

if [ -r $ZVBI ]
then
    CONFIGURE_FLAGS="$CONFIGURE_FLAGS --enable-libzvbi"
fi

# avresample
#CONFIGURE_FLAGS="$CONFIGURE_FLAGS --enable-avresample"


echo $CONFIGURE_FLAGS


DEPLOYMENT_TARGET="10.2"

if [ "$*" ]
then
	if [ "$*" = "lipo" ]
	then
		# skip compile
		COMPILE=
	else
		ARCHS="$*"
		if [ $# -eq 1 ]
		then
			# skip lipo
			LIPO=
		fi
	fi
fi

if [ "$COMPILE" ]
then
	if [ ! `which yasm` ]
	then
		echo 'Yasm not found'
		if [ ! `which brew` ]
		then
			echo 'Homebrew not found. Trying to install...'
                        ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" \
				|| exit 1
		fi
		echo 'Trying to install Yasm...'
		brew install yasm || exit 1
	fi
	if [ ! `which gas-preprocessor.pl` ]
	then
		echo 'gas-preprocessor.pl not found. Trying to install...'
		(curl -L https://github.com/libav/gas-preprocessor/raw/master/gas-preprocessor.pl \
			-o /usr/local/bin/gas-preprocessor.pl \
			&& chmod +x /usr/local/bin/gas-preprocessor.pl) \
			|| exit 1
	fi

	if [ ! -r $SOURCE ]
	then
		echo 'FFmpeg source not found. Trying to download...'
        curl http://www.ffmpeg.org/releases/$SOURCE.tar.bz2 | tar xj || exit 1

#        git submodule add -f https://github.com/MediaBrowser/ffmpeg.git
#        cd $SOURCE && git checkout 'emby/4.0.2/qsvfixes'

#        echo "Applying videotoolbox.c patch..."
#        git apply ../patches/ffmpeg/FFmpeg-devel-lavc-vt_hevc-fix-crash-if-vps_list-0-or-sps_list-0-are-null.patch || exit 1

        cd ..
	fi

	CWD=`pwd`
	for ARCH in $ARCHS
	do
		echo "building $ARCH..."
		mkdir -p "$SCRATCH/$ARCH"
		cd "$SCRATCH/$ARCH"

		CFLAGS="-arch $ARCH"
		if [ "$ARCH" = "i386" -o "$ARCH" = "x86_64" ]
		then
		    PLATFORM="appleTVSimulator"
		    CFLAGS="$CFLAGS -mtvos-simulator-version-min=$DEPLOYMENT_TARGET"
		else
		    PLATFORM="appleTVOS"
		    CFLAGS="$CFLAGS -mtvos-version-min=$DEPLOYMENT_TARGET -fembed-bitcode"
		    if [ "$ARCH" = "arm64" ]
		    then
		        EXPORT="GASPP_FIX_XCODE5=1"
		    fi
		fi

		XCRUN_SDK=`echo $PLATFORM | tr '[:upper:]' '[:lower:]'`
		CC="xcrun -sdk $XCRUN_SDK clang"

		# force "configure" to use "gas-preprocessor.pl" (FFmpeg 3.3)
		if [ "$ARCH" = "arm64" ]
		then
		    AS="gas-preprocessor.pl -arch aarch64 -- $CC"
		else
		    AS="$CC"
		fi

		CXXFLAGS="$CFLAGS"
		LDFLAGS="$CFLAGS"
		if [ "$X264" ]
		then
			CFLAGS="$CFLAGS -I$X264/include"
			LDFLAGS="$LDFLAGS -L$X264/lib"
		fi
		if [ "$FDK_AAC" ]
		then
			CFLAGS="$CFLAGS -I$FDK_AAC/include"
			LDFLAGS="$LDFLAGS -L$FDK_AAC/lib"
		fi
        if [ -r $ZVBI ]
        then
            CFLAGS="$CFLAGS -I$ZVBI/include"
            LDFLAGS="$LDFLAGS -L$ZVBI/lib"
        fi
        
        CFLAGS="$CFLAGS -I$CWD/build/release/libs-tvOS/thin/$ARCH/include"
        LDFLAGS="$LDFLAGS -L$CWD/build/release/libs-tvOS/thin/$ARCH/lib"
        
        export PKG_CONFIG_SYSROOT_DIR="$CWD/build/release/libs-tvOS/thin"
        export PKG_CONFIG_LIBDIR="$PKG_CONFIG_SYSROOT_DIR/$ARCH/lib/pkgconfig"

        TMPDIR=${TMPDIR/%\/} $CWD/$SOURCE/configure \
            --target-os=darwin \
            --arch=$ARCH \
            --cc="$CC" \
            --as="$AS" \
            $CONFIGURE_FLAGS \
            --extra-cflags="$CFLAGS" \
            --extra-ldflags="$LDFLAGS" \
            --prefix="$THIN/$ARCH" \
            --libdir="$CWD/build/release/libs-tvOS/thin/${ARCH}/lib" \
        || exit 1

         make -j4 install || exit 1
		cd $CWD
	done
fi

if [ "$LIPO" ]
then
	echo "building fat binaries..."
	mkdir -p $FAT/lib
	set - $ARCHS
	CWD=`pwd`
	cd $THIN/$1/lib
	for LIB in *.a
	do
		cd $CWD
		echo lipo -create `find $THIN -name $LIB` -output $FAT/lib/$LIB 1>&2
		lipo -create `find $THIN -name $LIB` -output $FAT/lib/$LIB || exit 1
	done

	cd $CWD
	cp -rf $THIN/$1/include $FAT
fi

echo Done
