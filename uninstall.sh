#!/bin/zsh
# Removes a SiType install made with install.sh.
set -euo pipefail

pkill -x SiType 2>/dev/null || true
rm -rf "$HOME/Library/Input Methods/SiType.app"
echo "Removed SiType. Remove it from System Settings → Keyboard → Input Sources if it is still listed."
