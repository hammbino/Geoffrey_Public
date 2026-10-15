#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP="$ROOT/build/Geoffrey.app"

fail() {
  printf 'NO  %s\n' "$1"
  exit 1
}

ok() { printf 'OK  %s\n' "$1"; }

[ -x "$APP/Contents/MacOS/Geoffrey" ] || fail "Build Geoffrey.app before running this check."
ok "Geoffrey.app executable exists"

rg -F 'ReturnToSendTextView' "$ROOT/app/GeoffreyApp.swift" >/dev/null || fail "Chat must use native Return handling."
rg -F 'event.modifierFlags.contains(.shift)' "$ROOT/app/GeoffreyApp.swift" >/dev/null || fail "Chat must preserve Shift-Return for a new line."
ok "Chat keyboard behavior is wired"

rg -F 'OperationalResultDisplay' "$ROOT/app/GeoffreyApp.swift" >/dev/null || fail "Operational results must use the structured renderer."
if rg -F 'Text(response.text)' "$ROOT/app/GeoffreyApp.swift" >/dev/null; then
  fail "Operational results must not fall back to a raw text wall."
fi
ok "Long operational results use structured UI"

rg -F 'if task.isDailyBriefing {' "$ROOT/app/GeoffreyApp.swift" >/dev/null || fail "Only the daily briefing may replace the briefing dashboard."
rg -F 'rateSection: {' "$ROOT/app/GeoffreyApp.swift" >/dev/null || fail "Briefing sections must support learning feedback."
ok "Briefing dashboard keeps rankings and section feedback"

if rg -n -i 'Terminal' "$ROOT/app/GeoffreyApp.swift" "$ROOT/app/Info.plist" >/dev/null; then
  fail "Geoffrey.app must not expose Terminal as part of an in-app workflow."
fi
ok "No Terminal workflow is exposed in Geoffrey.app"

"$ROOT/bin/geoffrey" app-status | rg -q '^app\tready$' || fail "Geoffrey engine is not ready for the app."
ok "Geoffrey engine reports ready"

accounts="$("$ROOT/bin/geoffrey" app-accounts)"
printf '%s' "$accounts" | node -e 'let input = ""; process.stdin.on("data", chunk => input += chunk).on("end", () => { const accounts = JSON.parse(input); if (!Array.isArray(accounts) || accounts.some(account => !account.id || !account.email || !account.calendar?.state)) process.exit(1); });' || fail "Account-health data is not valid."
ok "Account-health data is valid"

test ! -e "$ROOT/geoffrey-mcp/config/google-oauth.json" || fail "Private Google OAuth config must not be packaged."
ok "No private Google OAuth config in source"

printf 'Geoffrey Mac app check passed.\n'
