# AssaultCube Android port integration

This branch keeps the existing Darknes Strike project on `main` untouched while evaluating an upstream Android port.

## Upstream

- Repository: https://github.com/SarahRoseLives/AssaultCubeAndroid
- Integrated as a Git submodule at `vendor/assaultcube-android`.
- Upstream uses SDL2, gl4es, Android NDK and CMake; its README documents an ARM64 Android build.

## Important build checks before producing an APK

1. Clone this repository with submodules: `git clone --recurse-submodules https://github.com/def010375-ux/Darknes-Strike.git`, then check out `assaultcube-android-port`.
2. Initialize nested submodules: `git submodule update --init --recursive`.
3. Remove the machine-specific absolute `ndkPath` from upstream `android/app/build.gradle`; use the Gradle-managed NDK selected by `ndkVersion`.
4. Verify the exact upstream source/assets license notices before redistribution or branding changes. The upstream README describes a zlib-like license, but this repository snapshot has no root `LICENSE` file, so this still needs verification.
5. Build ARM64 first, install on a real Android device, and verify startup, touch input, audio, bots and map loading before modifying gameplay.

## Scope

This is an upstream integration checkpoint, not an APK or a completed port. The existing Godot project remains on `main`; no original project files are overwritten.
