#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE="$ROOT/app/GeoffreyApp.swift"
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
  "$1" -sdk "$SDK" -target "$ARCH-apple-macosx14.0" -parse-as-library "$SOURCE" \
    -o "$APP/Contents/MacOS/Geoffrey" -framework SwiftUI -framework AppKit
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
cp "$ICON" "$APP/Contents/Resources/Geoffrey.icns"
echo "Built $APP"
