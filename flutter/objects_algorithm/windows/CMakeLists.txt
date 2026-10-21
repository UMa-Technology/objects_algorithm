# Windows build entry point.
#
# The Flutter toolchain only guarantees the CMake 3.14+ bundled with Visual Studio; don't raise this floor.
cmake_minimum_required(VERSION 3.14)

set(PROJECT_NAME "objects_algorithm")
project(${PROJECT_NAME} LANGUAGES CXX)

# The actual compile rules are shared with Android, see ../src/CMakeLists.txt.
add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/../src" "${CMAKE_CURRENT_BINARY_DIR}/shared")

# Tell the Flutter toolchain which artifacts to copy next to the exe.
# The host's flutter/generated_plugins.cmake collects every plugin's
# <plugin_name>_bundled_libraries and installs them into the runner output directory.
#
# This mechanism **only covers Flutter plugins**. Plain targets a host adds via its own
# add_subdirectory don't go into PLUGIN_BUNDLED_LIBRARIES and still need hand-written
# POST_BUILD copy steps to put their DLLs in the exe directory -- a host that already has such
# copy steps for its own native libraries must keep them; this plugin doesn't replace them.
set(objects_algorithm_bundled_libraries
  $<TARGET_FILE:objects_algorithm>
  PARENT_SCOPE
)
