set(CMAKE_SYSTEM_NAME "Darwin")
set(CMAKE_SYSTEM_PROCESSOR "x86_64")
set(CMAKE_OSX_ARCHITECTURES "x86_64")
set(CMAKE_OSX_SYSROOT "iphonesimulator")
set(CMAKE_C_COMPILER clang)

set(CMAKE_CXX_COMPILER clang++)


# No runtime CPU detection for cross-compiled iOS Simulator targets.
set(CONFIG_RUNTIME_CPU_DETECT 0 CACHE STRING "")
