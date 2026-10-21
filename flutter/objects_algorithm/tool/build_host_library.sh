#!/usr/bin/env bash
#
# Build the native library for the host machine, for `flutter test`.
#
# `flutter test` runs in a plain Dart VM that doesn't link the plugin's native code, so
# DynamicLibrary.process() is empty. bind.dart detects this and falls back to the artifact
# under build/host/; this script produces it.
#
# For tests only; not part of any platform's release build.

set -euo pipefail

PLUGIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PLUGIN_ROOT"

cmake -S src -B build/host-cmake -DCMAKE_BUILD_TYPE=Release >/dev/null
cmake --build build/host-cmake -j"$(sysctl -n hw.ncpu 2>/dev/null || nproc)" >/dev/null

mkdir -p build/host
lib="$(find build/host-cmake -maxdepth 1 -name 'libobjects_algorithm.*' \
       ! -name '*.a' | head -1)"
[ -n "$lib" ] || { echo "build artifact not found" >&2; exit 1; }
cp "$lib" "build/host/$(basename "$lib")"

echo "build/host/$(basename "$lib")"
echo "  KPCAA exported symbols: $(nm -gU "build/host/$(basename "$lib")" 2>/dev/null \
  | awk '$2=="T"{print $3}' | grep -c '^_KPCAA' || echo '?')"
