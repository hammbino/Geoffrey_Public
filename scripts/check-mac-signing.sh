#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [ "$(uname -s)" != Darwin ]; then
  printf 'signing_status=blocked reason=macos_required\n'
  exit 2
fi
if ! identities="$(/usr/bin/security find-identity -v -p codesigning 2>/dev/null)"; then
  printf 'signing_status=blocked reason=keychain_identity_lookup_failed\n'
  exit 2
fi
if [ -n "${GEOFFREY_CODESIGN_IDENTITY:-}" ]; then
  printf '%s\n' "$identities" | python3 "$ROOT/scripts/check-mac-signing-identity.py" --identity="$GEOFFREY_CODESIGN_IDENTITY"
else
  printf '%s\n' "$identities" | python3 "$ROOT/scripts/check-mac-signing-identity.py"
fi
