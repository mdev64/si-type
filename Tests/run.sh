#!/bin/zsh
# Runs the controller tests inside a copy of the built bundle so resources resolve.
set -euo pipefail
cd "${0:A:h}/.."
[[ -d build/SiType.app ]] || ./build.sh
T=build/test/SiType.app
rm -rf build/test && mkdir -p build/test && cp -R build/SiType.app "$T"
swiftc -framework Cocoa -framework InputMethodKit \
    Sources/InputController.swift Sources/Keymap.swift Tests/main.swift \
    -o "$T/Contents/MacOS/SiTypeTests"
"$T/Contents/MacOS/SiTypeTests"
