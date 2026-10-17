#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
FIXTURE="$WORK/source"
mkdir -p "$FIXTURE"
# Use committed source only, never the developer's ignored/private files.
git -C "$ROOT" archive HEAD | tar -x -C "$FIXTURE"
# Exercise the working versions of the packaging code under review.
cp "$ROOT/scripts/build-dist.sh" "$ROOT/scripts/check-claude-setup.sh" "$ROOT/scripts/check-release-safety.sh" "$FIXTURE/scripts/"
mkdir -p "$FIXTURE/.release-evidence" "$FIXTURE/docs/.release-evidence"
printf '{"synthetic_owner_evidence":true}\n' > "$FIXTURE/.release-evidence/dustin-gate.json"
printf 'synthetic nested evidence\n' > "$FIXTURE/docs/.release-evidence/record.txt"
chmod 600 "$FIXTURE/.release-evidence/dustin-gate.json" "$FIXTURE/docs/.release-evidence/record.txt"
"$FIXTURE/scripts/build-dist.sh" > "$WORK/build.log" 2>&1
"$FIXTURE/scripts/check-claude-setup.sh" > "$WORK/check.log" 2>&1 || {
  printf 'NO  Synthetic evidence must be excluded without breaking package freshness.\n'
  exit 1
}
for bundle in "$FIXTURE/dist/Geoffrey-for-Claude-Mauricio.zip" "$FIXTURE/dist/Geoffrey-for-Claude-Full-with-Reference.zip"; do
  unzip -Z1 "$bundle" > "$WORK/entries.txt"
  if rg -q '(^|/)\.release-evidence(/|$)' "$WORK/entries.txt"; then
    printf 'NO  Owner evidence was included in a repository bundle.\n'
    exit 1
  fi
done

# A pre-existing or tampered bundle must fail the checker too.
mkdir -p "$WORK/inject/Geoffrey/.release-evidence"
printf 'synthetic forbidden evidence\n' > "$WORK/inject/Geoffrey/.release-evidence/record.txt"
for bundle in "$FIXTURE/dist/Geoffrey-for-Claude-Mauricio.zip" "$FIXTURE/dist/Geoffrey-for-Claude-Full-with-Reference.zip"; do
  (cd "$WORK/inject" && zip -q "$bundle" Geoffrey/.release-evidence/record.txt)
done
if "$FIXTURE/scripts/check-claude-setup.sh" > "$WORK/reject.log" 2>&1; then
  printf 'NO  Package checker accepted injected owner evidence.\n'
  exit 1
fi
[ "$(rg -c '^NO  Bundle contains a forbidden private or development path:' "$WORK/reject.log")" = 2 ] || {
  printf 'NO  Both bundle safety checks must reject owner evidence.\n'
  exit 1
}

APP="$WORK/Geoffrey.app"
ENGINE="$APP/Contents/Resources/GeoffreyEngine"
mkdir -p "$ENGINE/bin" "$APP/Contents/Resources/.release-evidence"
printf '#!/bin/sh\nexit 0\n' > "$ENGINE/bin/geoffrey"
chmod +x "$ENGINE/bin/geoffrey"
if "$FIXTURE/scripts/check-release-safety.sh" "$APP" > "$WORK/app.log" 2>&1; then
  printf 'NO  Native payload checker accepted owner evidence outside the engine.\n'
  exit 1
fi
rg -q '^NO  Owner release evidence was packaged\.' "$WORK/app.log"
printf 'OK  Owner evidence stays out of both repository bundles and native app payloads.\n'
