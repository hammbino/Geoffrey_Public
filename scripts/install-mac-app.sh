#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET="$HOME/Applications/Geoffrey.app"

"$ROOT/scripts/build-mac-app.sh"
mkdir -p "$HOME/Applications"
rm -rf "$TARGET"
ditto "$ROOT/build/Geoffrey.app" "$TARGET"
xattr -dr com.apple.quarantine "$TARGET" 2>/dev/null || true
echo "Geoffrey.app is ready in Applications."
