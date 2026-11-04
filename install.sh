#!/bin/zsh
# Installs SiType.app into ~/Library/Input Methods and registers it.
set -euo pipefail

cd "${0:A:h}"
./build.sh

DEST="$HOME/Library/Input Methods"
mkdir -p "$DEST"
pkill -x SiType 2>/dev/null || true
rm -rf "$DEST/SiType.app"
cp -R build/SiType.app "$DEST/"

"$DEST/SiType.app/Contents/MacOS/SiType" --register
echo "Installed. Add it in System Settings → Keyboard → Input Sources → Edit → + → Sinhala → SiType."
