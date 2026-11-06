#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
AC_DIR="$ROOT/vendor/assaultcube-android"
APP_GRADLE="$AC_DIR/android/app/build.gradle"
ASSETS="$AC_DIR/android/app/src/main/assets"

if [[ ! -f "$APP_GRADLE" ]]; then
  echo "AssaultCube submodule is missing. Run: git submodule update --init --recursive" >&2
  exit 1
fi

# Remove the upstream author's machine-specific Windows NDK path.
sed -i.bak '/^[[:space:]]*ndkPath[[:space:]]/d' "$APP_GRADLE"
rm -f "$APP_GRADLE.bak"

mkdir -p "$ASSETS"
rm -rf "$ASSETS/packages" "$ASSETS/config"
cp -a "$AC_DIR/packages" "$ASSETS/packages"
cp -a "$AC_DIR/config" "$ASSETS/config"

echo "AssaultCube Android project prepared."
echo "Next: install Android NDK 25.1.8937393 and CMake 3.22.1, then run:"
echo "  cd vendor/assaultcube-android/android"
echo "  ./build_deps.sh arm64-v8a"
echo "  gradle assembleDebug"
