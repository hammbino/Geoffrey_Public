#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE="$ROOT/app/GeoffreyApp.swift"
PLIST="$ROOT/app/Info.plist"
APP="$ROOT/build/Geoffrey.app"

if [ "$(uname -s)" != "Darwin" ]; then
  echo "Geoffrey.app can only be built on a Mac."
  exit 1
fi

command -v swiftc >/dev/null 2>&1 || {
  echo "Apple's Swift tools are needed to build Geoffrey.app. Install Xcode Command Line Tools, then try again."
  exit 1
}

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
swiftc -parse-as-library "$SOURCE" -o "$APP/Contents/MacOS/Geoffrey" -framework SwiftUI -framework AppKit
cp "$PLIST" "$APP/Contents/Info.plist"
echo "Built $APP"
