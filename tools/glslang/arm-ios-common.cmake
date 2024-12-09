set(CMAKE_SYSTEM_NAME "Darwin")
set(CMAKE_OSX_SYSROOT "iphoneos")
set(CMAKE_C_COMPILER clang)

set(CMAKE_CXX_COMPILER clang++)


# No runtime cpu detect for arm*-ios targets.
set(CONFIG_RUNTIME_CPU_DETECT 0 CACHE STRING "")
