# Shared build definition for the AA+ astronomy library.
#
# Two consumers:
#   - Android: externalNativeBuild in android/build.gradle points straight at this file
#   - Windows: windows/CMakeLists.txt pulls this file in via add_subdirectory
# iOS/macOS don't use CMake; they go through CocoaPods, see the forwarding files under
# ios|macos/Classes/generated.
#
# The compile options here follow a host app's verified Android and Windows CMake
# configurations. Every deviation from them is explained inline below.
#
# The Flutter toolchain only guarantees CMake 3.10+ on developer machines; don't raise this floor.
cmake_minimum_required(VERSION 3.10)

project(objects_algorithm_library VERSION 0.2.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Deviation: these two lines apply to non-MSVC only.
# The host app sets them unconditionally, which is fine there because its
# windows/CMakeLists.txt has cmake_policy(VERSION 3.14...3.25): CMP0091 is NEW, so runtime
# library switches like /MD go through CMAKE_MSVC_RUNTIME_LIBRARY rather than
# CMAKE_CXX_FLAGS_<CONFIG>, and overwriting the latter is harmless.
# This file, however, declares cmake_minimum_required(VERSION 3.10), so the subdirectory resets
# policies to 3.10 defaults and CMP0091 becomes OLD -- /MD then lives in CMAKE_CXX_FLAGS_RELEASE,
# and an unconditional overwrite drops it, linking the plugin DLL (and any sibling DLLs) against
# the static CRT, mismatching the host's runtime library.
# MSVC also doesn't understand -O0 / -g (D9002). Its own defaults are the right choice.
if(NOT MSVC)
  set(CMAKE_CXX_FLAGS_DEBUG "-O0 -g")
  set(CMAKE_CXX_FLAGS_RELEASE "-O2 -DNDEBUG")
endif()

# Deviation: the aaplus static library is linked into a shared library, so require
# position-independent code explicitly. Android's clang defaults to PIC anyway; this line
# makes it hold on other ELF platforms (Linux) too.
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

if(MSVC)
  add_compile_options(/std:c++17 /permissive-)
  # Some aaplus and aainterface files contain non-ASCII characters in comments. On
  # Chinese-locale Windows the system code page is 936 (GBK); without /utf-8 the sources are
  # parsed as GBK and trigger C4819.
  # The host app adds /utf-8 globally in its root windows/CMakeLists.txt, but that only
  # covers that one host; the plugin can't rely on every host doing so, so it adds its own.
  add_compile_options(/utf-8)
  # aaplus is vendored byte-identical to the upstream release, whose few non-ASCII comment
  # characters are Latin-1 / Windows-1252 rather than UTF-8. Under /utf-8 MSVC reports those
  # bytes as C4828; they are only in comments, so silence it.
  add_compile_options(/wd4828)
  add_compile_options(/wd4996)
endif()

# --- aaplus: upstream AA+ algorithm implementation, built as a static library ---
file(GLOB AAPLUS_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/aaplus/*.cpp")

# Deviation: exclude AATest.cpp. It's AA+'s upstream test driver with an int main().
# In the host app it sat unreferenced in a static library and the linker dropped it -- pure luck.
# On Apple platforms every source file is compiled straight into the pod target, so that main
# would clash with the host app's main. Excluded on all four platforms for consistency.
list(FILTER AAPLUS_SOURCES EXCLUDE REGEX "AATest\\.cpp$")

# Deviation: the target is named aaplus_core rather than aaplus. The host app's Windows build
# already has a target named aaplus, and while both coexist during migration CMake would fail
# on the duplicate name.
add_library(aaplus_core STATIC ${AAPLUS_SOURCES})
target_include_directories(aaplus_core PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}/aaplus")

# --- aainterface: extern "C" interface layer, the symbols dart:ffi actually looks up ---
file(GLOB AAINTERFACE_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/aainterface/*.cpp")

add_library(objects_algorithm SHARED ${AAINTERFACE_SOURCES})
target_link_libraries(objects_algorithm PRIVATE aaplus_core)
target_include_directories(objects_algorithm PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/aainterface")

set_target_properties(objects_algorithm PROPERTIES OUTPUT_NAME "objects_algorithm")

target_compile_definitions(objects_algorithm PUBLIC DART_SHARED_LIB)

if (ANDROID)
  # Support Android 15 16k page size.
  target_link_options(objects_algorithm PRIVATE "-Wl,-z,max-page-size=16384")
endif()

if(WIN32)
  # MSVC exports nothing by default, and KPCAA* carry no __declspec(dllexport).
  # Have CMake generate a .def that exports every symbol in this target's object files.
  # Equivalent to the set(CMAKE_WINDOWS_EXPORT_ALL_SYMBOLS ON) variable form.
  set_target_properties(objects_algorithm PROPERTIES WINDOWS_EXPORT_ALL_SYMBOLS TRUE)
endif()
