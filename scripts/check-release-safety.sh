#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP="${1:-$ROOT/build/Geoffrey.app}"
ENGINE="$APP/Contents/Resources/GeoffreyEngine"

fail() {
  printf 'NO  %s\n' "$1" >&2
  exit 1
}

ok() { printf 'OK  %s\n' "$1"; }

[ -d "$ENGINE" ] || fail "Geoffrey's embedded engine is missing: $ENGINE"
[ -x "$ENGINE/bin/geoffrey" ] || fail "Geoffrey's embedded command engine is missing or not executable."

for forbidden in \
  "$ENGINE/.git" \
  "$ENGINE/build" \
  "$ENGINE/dist" \
  "$ENGINE/release-screenshots" \
  "$ENGINE/onboarding/recipients" \
  "$ENGINE/geoffrey-mcp/config/google-oauth.json" \
  "$ENGINE/geoffrey-mcp/node_modules/.cache"; do
  [ ! -e "$forbidden" ] || fail "Unsafe release path was packaged: ${forbidden#"$APP/"}"
done

unsafe_file="$(find "$ENGINE" -type f \( \
  -name '.env' -o \
  -name '.env.*' -o \
  -name 'accounts.json' -o \
  -name '*.token' -o \
  -name '*.secret' \
\) -print -quit)"
[ -z "$unsafe_file" ] || fail "Potential credential file was packaged: ${unsafe_file#"$APP/"}"

git_metadata="$(find "$ENGINE" -type d -name '.git' -print -quit)"
[ -z "$git_metadata" ] || fail "Git metadata was packaged: ${git_metadata#"$APP/"}"

ok "Embedded engine uses the release allowlist"
ok "No raw account, token, environment, screenshot, or Git metadata files are packaged"
