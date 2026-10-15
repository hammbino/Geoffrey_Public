#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET="/Applications/Geoffrey.app"

"$ROOT/scripts/build-mac-app.sh"
mkdir -p "/Applications"
rm -rf "$TARGET"
ditto "$ROOT/build/Geoffrey.app" "$TARGET"
xattr -dr com.apple.quarantine "$TARGET" 2>/dev/null || true
# Geoffrey.app uses this setting to find the command engine and private-memory
# helpers. Pair it with the copy that was just installed so an older checkout
# cannot silently service a newer app bundle.
defaults write com.geoffrey.assistant geoffreyHome -string "$ROOT"
echo "Geoffrey.app is ready at $TARGET"
open "$TARGET"
