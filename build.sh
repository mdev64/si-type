#!/bin/zsh
# Builds build/SiType.app for this Mac's architecture.
# Set ARCHS="arm64 x86_64" for a universal build (needs full Xcode).
# Set VERSION=1.2.3 to stamp the bundle version (defaults to Info.plist).
set -euo pipefail

cd "${0:A:h}"
APP=build/SiType.app
TMP=build/tmp
MIN_OS=11.0
ARCHS=(${=ARCHS:-$(uname -m)})

rm -rf "$APP" "$TMP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" "$TMP"

for arch in $ARCHS; do
    swiftc -O -target "$arch-apple-macos$MIN_OS" \
        -framework Cocoa -framework InputMethodKit \
        Sources/*.swift -o "$TMP/SiType-$arch"
done
lipo -create "$TMP"/SiType-* -output "$APP/Contents/MacOS/SiType"

cp Resources/Info.plist "$APP/Contents/"
if [[ -n "${VERSION:-}" ]]; then
    /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" \
        -c "Set :CFBundleVersion $VERSION" "$APP/Contents/Info.plist"
fi
printf 'APPL????' > "$APP/Contents/PkgInfo"
cp -R Resources/en.lproj "$APP/Contents/Resources/"
for map in phonetic wijesekara; do
    plutil -convert binary1 -o "$APP/Contents/Resources/$map.strings" "Resources/$map.strings"
done

# Menu-bar icon (16pt with @2x) and app icon, both from icon.tiff.
sips -z 16 16 icon.tiff --out "$TMP/menu16.png" -s format png >/dev/null
sips -z 32 32 icon.tiff --out "$TMP/menu32.png" -s format png >/dev/null
tiffutil -cathidpicheck "$TMP/menu16.png" "$TMP/menu32.png" -out "$APP/Contents/Resources/sitype.tiff" 2>/dev/null

ICONSET="$TMP/SiType.iconset"
mkdir -p "$ICONSET"
for size in 16 32 128 256; do
    sips -z $size $size icon.tiff --out "$ICONSET/icon_${size}x${size}.png" -s format png >/dev/null
    sips -z $((size * 2)) $((size * 2)) icon.tiff --out "$ICONSET/icon_${size}x${size}@2x.png" -s format png >/dev/null
done
sips -z 512 512 icon.tiff --out "$ICONSET/icon_512x512.png" -s format png >/dev/null
iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/SiType.icns"

codesign --force --sign - "$APP"
rm -rf "$TMP"
echo "Built $APP"
