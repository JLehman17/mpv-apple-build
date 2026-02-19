# Source Versions

if [ "$BUILD_EXT" == "watchos" ]
then
    export FF_VERSION="4.2.1-watchos"
else
    export FF_VERSION="4.2.1" # maccatlyst version is FF_VERSION="4.2.1"
fi
export FREETYPE_VERSION="2.10.1"
export FRIBIDI_VERSION="1.0.16"
export GLSLANG_VERSION="14.1.0"
export HARFBUZZ_VERSION="2.2.0"
export LCMS_VERSION="2.16"
export LIBASS_VERSION="0.17.3"
export PLACEBO_VERSION="6.338.2" #VERSION="3.120.3" # needed for tmm1's moltenVK for iOS/tvOS
export MOLTENVK_VERSION="1.2.8"
if [ "$BUILD_EXT" == "watchos" ]
then
    # 0.33.0 doesn't use posix-spawn which is prohibited on watchOS... Unfortuantely it also make libass a requirement.
    export MPV_VERSION="0.32.0-watchos"
else
    export MPV_VERSION="0.38.0-moltenvk"
fi
export OPENSSL_VERSION="3.0.3"
export ZVBI_VERSION="0.2.35"
