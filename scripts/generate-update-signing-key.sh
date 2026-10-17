#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT="${1:-}"

[ -n "$OUTPUT" ] || { echo "Usage: $0 /absolute/private/location/geoffrey-update.key"; exit 2; }
case "$OUTPUT" in
  /*) ;;
  *) echo "Use an absolute private-key path outside the Geoffrey repository."; exit 2 ;;
esac
case "$OUTPUT" in
  "$ROOT"/*) echo "The update private key must stay outside the Geoffrey repository."; exit 2 ;;
esac

TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TEMP_DIR"' EXIT
SWIFTC="$(command -v swiftc)"
for candidate in /opt/homebrew/opt/swift/*.xctoolchain/usr/bin/swiftc /usr/local/opt/swift/*.xctoolchain/usr/bin/swiftc; do
  if [ -x "$candidate" ]; then SWIFTC="$candidate"; break; fi
done
SDK="$(xcrun --sdk macosx --show-sdk-path)"
ARCH="$(uname -m)"
CLANG_MODULE_CACHE_PATH="$TEMP_DIR/module-cache" \
  "$SWIFTC" -sdk "$SDK" -target "$ARCH-apple-macosx14.0" -parse-as-library \
  "$ROOT/scripts/GeoffreyUpdateKeyGenerator.swift" -o "$TEMP_DIR/generate-key"

echo "Geoffrey update public key:"
"$TEMP_DIR/generate-key" "$OUTPUT"
echo "Private key written with owner-only permissions to: $OUTPUT"
echo "Back it up securely. Never add it to Geoffrey, GitHub, an app bundle, or a release archive."
