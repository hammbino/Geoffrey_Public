#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET="/Applications/Geoffrey.app"

"$ROOT/scripts/build-mac-app.sh"
mkdir -p "/Applications"
rm -rf "$TARGET"
ditto "$ROOT/build/Geoffrey.app" "$TARGET"
xattr -dr com.apple.quarantine "$TARGET" 2>/dev/null || true
# Geoffrey.app installs its version-matched engine in Application Support on
# first launch. Existing ~/.geoffrey accounts and the current-memory pointer
# remain in place and are migrated non-destructively by the app.
echo "Geoffrey.app is ready at $TARGET"
open "$TARGET"
