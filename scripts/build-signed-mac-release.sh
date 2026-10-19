#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLIST="$ROOT/app/Info.plist"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$PLIST")"
BUILD="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$PLIST")"
RELEASE_DIR="$ROOT/build/releases/$VERSION"
ARCHIVE="$RELEASE_DIR/Geoffrey-$VERSION.zip"
MANIFEST="$RELEASE_DIR/update.json"
SIGNER="$RELEASE_DIR/GeoffreyUpdateManifestSigner"

# Refuse missing, ad-hoc, wrong-type, or unavailable publisher identities
# before creating output or rebuilding the development app.
"$ROOT/scripts/check-mac-signing.sh"

: "${GEOFFREY_CODESIGN_IDENTITY:?Set GEOFFREY_CODESIGN_IDENTITY to the Developer ID Application identity.}"
: "${GEOFFREY_UPDATE_PUBLIC_KEY:?Set GEOFFREY_UPDATE_PUBLIC_KEY to the base64 Ed25519 public key.}"
: "${GEOFFREY_UPDATE_PRIVATE_KEY_FILE:?Set GEOFFREY_UPDATE_PRIVATE_KEY_FILE to the owner-only private key file.}"
: "${GEOFFREY_RELEASE_NOTES_FILE:?Set GEOFFREY_RELEASE_NOTES_FILE to the reviewed release-notes file.}"
: "${GEOFFREY_NOTARY_PROFILE:?Set GEOFFREY_NOTARY_PROFILE to an Apple notarytool Keychain profile.}"

case "$VERSION" in
  *[!0-9.]*|'') echo "Invalid app version: $VERSION"; exit 1 ;;
esac

[ ! -e "$RELEASE_DIR" ] || {
  echo "Release output already exists: $RELEASE_DIR"
  exit 1
}
[ -f "$GEOFFREY_UPDATE_PRIVATE_KEY_FILE" ] || { echo "Update private key file is missing."; exit 1; }
[ -f "$GEOFFREY_RELEASE_NOTES_FILE" ] || { echo "Release notes file is missing."; exit 1; }

mkdir -p "$RELEASE_DIR"
GEOFFREY_CODESIGN_IDENTITY="$GEOFFREY_CODESIGN_IDENTITY" \
GEOFFREY_UPDATE_PUBLIC_KEY="$GEOFFREY_UPDATE_PUBLIC_KEY" \
  "$ROOT/scripts/build-mac-app.sh"

MINIMUM_MACOS="$(/usr/libexec/PlistBuddy -c 'Print :LSMinimumSystemVersion' "$ROOT/build/Geoffrey.app/Contents/Info.plist")"
codesign --verify --deep --strict --verbose=2 "$ROOT/build/Geoffrey.app"

PRE_NOTARY_ARCHIVE="$RELEASE_DIR/Geoffrey-$VERSION.notary.zip"
ditto -c -k --keepParent "$ROOT/build/Geoffrey.app" "$PRE_NOTARY_ARCHIVE"
xcrun notarytool submit "$PRE_NOTARY_ARCHIVE" --keychain-profile "$GEOFFREY_NOTARY_PROFILE" --wait
xcrun stapler staple "$ROOT/build/Geoffrey.app"
xcrun stapler validate "$ROOT/build/Geoffrey.app"
spctl --assess --type execute --verbose=2 "$ROOT/build/Geoffrey.app"
unlink "$PRE_NOTARY_ARCHIVE"

ditto -c -k --keepParent "$ROOT/build/Geoffrey.app" "$ARCHIVE"

SWIFTC="$(command -v swiftc)"
for candidate in /opt/homebrew/opt/swift/*.xctoolchain/usr/bin/swiftc /usr/local/opt/swift/*.xctoolchain/usr/bin/swiftc; do
  if [ -x "$candidate" ]; then SWIFTC="$candidate"; break; fi
done
SDK="$(xcrun --sdk macosx --show-sdk-path)"
ARCH="$(uname -m)"
CLANG_MODULE_CACHE_PATH="${TMPDIR:-/tmp}/geoffrey-clang-module-cache" \
  "$SWIFTC" -sdk "$SDK" -target "$ARCH-apple-macosx14.0" -parse-as-library \
  "$ROOT/scripts/GeoffreyUpdateManifestSigner.swift" -o "$SIGNER"

ARCHIVE_URL="${GEOFFREY_UPDATE_ARCHIVE_URL:-https://github.com/hammbino/Geoffrey_Public/releases/download/v$VERSION/Geoffrey-$VERSION.zip}"
"$SIGNER" \
  --archive "$ARCHIVE" \
  --archive-url "$ARCHIVE_URL" \
  --notes "$GEOFFREY_RELEASE_NOTES_FILE" \
  --private-key "$GEOFFREY_UPDATE_PRIVATE_KEY_FILE" \
  --output "$MANIFEST" \
  --version "$VERSION" \
  --build "$BUILD" \
  --minimum-macos "$MINIMUM_MACOS"

unlink "$SIGNER"
echo "Signed, notarized Geoffrey release ready in $RELEASE_DIR"
