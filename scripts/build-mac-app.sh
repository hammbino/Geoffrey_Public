#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE="$ROOT/app/GeoffreyApp.swift"
STREAM_SOURCE="$ROOT/app/ClaudeStream.swift"
READINESS_SOURCE="$ROOT/app/GeoffreyReadiness.swift"
SETUP_SOURCE="$ROOT/app/GeoffreySetup.swift"
CONNECTIONS_SOURCE="$ROOT/app/GeoffreyConnections.swift"
MEMORY_SOURCE="$ROOT/app/GeoffreyMemory.swift"
AUTOMATIONS_SOURCE="$ROOT/app/GeoffreyAutomations.swift"
UPDATER_SOURCE="$ROOT/app/GeoffreyUpdater.swift"
UPDATE_HELPER_SOURCE="$ROOT/app/GeoffreyUpdateHelper.swift"
PLIST="$ROOT/app/Info.plist"
ICON="$ROOT/app/Geoffrey.icns"
APP="$ROOT/build/Geoffrey.app"

if [ "$(uname -s)" != "Darwin" ]; then
  echo "Geoffrey.app can only be built on a Mac."
  exit 1
fi

command -v swiftc >/dev/null 2>&1 || {
  echo "Apple's Swift tools are needed to build Geoffrey.app. Install Xcode Command Line Tools, then try again."
  exit 1
}

if [ ! -f "$ICON" ]; then
  echo "Geoffrey's app icon is missing: $ICON"
  exit 1
fi

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

SDK="$(xcrun --sdk macosx --show-sdk-path)"
ARCH="$(uname -m)"
SYSTEM_SWIFTC="$(command -v swiftc)"
SWIFTC="$SYSTEM_SWIFTC"
for candidate in /opt/homebrew/opt/swift/*.xctoolchain/usr/bin/swiftc /usr/local/opt/swift/*.xctoolchain/usr/bin/swiftc; do
  if [ -x "$candidate" ]; then
    SWIFTC="$candidate"
    break
  fi
done

build_app() {
  CLANG_MODULE_CACHE_PATH="${TMPDIR:-/tmp}/geoffrey-clang-module-cache" \
    "$1" -sdk "$SDK" -target "$ARCH-apple-macosx14.0" -parse-as-library \
    "$ROOT/app/GeoffreyCommand.swift" "$SOURCE" "$STREAM_SOURCE" "$READINESS_SOURCE" "$SETUP_SOURCE" "$CONNECTIONS_SOURCE" "$MEMORY_SOURCE" "$AUTOMATIONS_SOURCE" "$UPDATER_SOURCE" \
    -o "$APP/Contents/MacOS/Geoffrey" -framework SwiftUI -framework AppKit -framework Security
}

build_update_helper() {
  CLANG_MODULE_CACHE_PATH="${TMPDIR:-/tmp}/geoffrey-clang-module-cache" \
    "$1" -sdk "$SDK" -target "$ARCH-apple-macosx14.0" "$UPDATE_HELPER_SOURCE" \
    -o "$APP/Contents/Resources/GeoffreyUpdateHelper" -framework Security
}

if ! build_app "$SWIFTC"; then
  if [ "$SWIFTC" != "$SYSTEM_SWIFTC" ]; then
    echo "Geoffrey could not build with the installed Swift toolchain."
    exit 1
  fi
  if ! command -v brew >/dev/null 2>&1; then
    echo "Geoffrey needs a compatible Swift compiler. Install Homebrew, then try again."
    exit 1
  fi
  echo "Apple's Swift tools need a repair. Installing Geoffrey's isolated Swift build tool..."
  brew install swift
  for candidate in /opt/homebrew/opt/swift/*.xctoolchain/usr/bin/swiftc /usr/local/opt/swift/*.xctoolchain/usr/bin/swiftc; do
    if [ -x "$candidate" ]; then
      SWIFTC="$candidate"
      break
    fi
  done
  if [ "$SWIFTC" = "$SYSTEM_SWIFTC" ] || ! build_app "$SWIFTC"; then
    echo "Geoffrey could not build its Mac app. Please run Geoffrey update and try again."
    exit 1
  fi
fi

cp "$PLIST" "$APP/Contents/Info.plist"
if [ -n "${GEOFFREY_UPDATE_PUBLIC_KEY:-}" ]; then
  /usr/libexec/PlistBuddy -c "Add :GeoffreyUpdatePublicKey string $GEOFFREY_UPDATE_PUBLIC_KEY" "$APP/Contents/Info.plist"
fi
cp "$ICON" "$APP/Contents/Resources/Geoffrey.icns"
build_update_helper "$SWIFTC"
ENGINE="$APP/Contents/Resources/GeoffreyEngine"
mkdir -p "$ENGINE"

# Build the embedded engine from an explicit allowlist. Geoffrey's working
# checkout can contain private OAuth material, screenshots, Git history, old
# release archives, and local recipient packets. None of those belong in a
# customer application bundle.
ENGINE_PATHS=(
  ".claude"
  "bin"
  "core"
  "docs"
  "geoffrey-mcp"
  "memory-template"
  "packs"
  "plugins"
  "onboarding/recipient-packet-template.md"
  "CLAUDE.md"
  "HANDOFF.md"
  "PROJECT.md"
  "README.md"
  "START_HERE.md"
)

for path in "${ENGINE_PATHS[@]}"; do
  [ -e "$ROOT/$path" ] || {
    echo "Required Geoffrey engine path is missing: $path"
    exit 1
  }
  rsync -aR \
    --exclude '.DS_Store' \
    --exclude '.env' \
    --exclude '.env.*' \
    --exclude 'accounts.json' \
    --exclude '*.token' \
    --exclude '*.secret' \
    --exclude 'config/google-oauth.json' \
    --exclude 'node_modules/.cache/' \
    --exclude 'node_modules/.bin/' \
    "$ROOT/./$path" "$ENGINE/"
done

CLANG_MODULE_CACHE_PATH="${TMPDIR:-/tmp}/geoffrey-clang-module-cache" \
  "$SWIFTC" -sdk "$SDK" -target "$ARCH-apple-macosx14.0" -parse-as-library \
  "$ROOT/app/GeoffreyKeychain.swift" -o "$ENGINE/geoffrey-mcp/bin/geoffrey-keychain" -framework Security

python3 "$ROOT/scripts/bundle-mac-runtime.py" "$APP"

"$ROOT/scripts/check-release-safety.sh" "$APP"
if [ -n "${GEOFFREY_CODESIGN_IDENTITY:-}" ]; then
  codesign --force --deep --preserve-metadata=entitlements --options runtime --timestamp --sign "$GEOFFREY_CODESIGN_IDENTITY" "$APP"
else
  codesign --force --deep --preserve-metadata=entitlements --sign - "$APP"
fi
echo "Built $APP"
