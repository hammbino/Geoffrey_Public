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

rg -F '.onSubmit(send)' "$ROOT/app/GeoffreyApp.swift" >/dev/null || fail "Chat must send when the owner presses Return."
rg -F 'TextField("Ask about a task, decision, or problem you want off your plate"' "$ROOT/app/GeoffreyApp.swift" >/dev/null || fail "Chat must use a native editable text field."
ok "Chat input is a native Return-to-send field"

rg -F 'OperationalResultDisplay' "$ROOT/app/GeoffreyApp.swift" >/dev/null || fail "Operational results must use the structured renderer."
rg -F 'ResultEmptyState' "$ROOT/app/GeoffreyApp.swift" >/dev/null || fail "Operational results need an explicit no-items state."
rg -F 'Operational result feedback:' "$ROOT/app/GeoffreyApp.swift" >/dev/null || fail "Operational result sections must support learning feedback."
if rg -F 'Text(response.text)' "$ROOT/app/GeoffreyApp.swift" >/dev/null; then
  fail "Operational results must not fall back to a raw text wall."
fi
ok "Long operational results use structured UI"

capability_context="$("$ROOT/bin/geoffrey" app-context --task capability-review)"
printf '%s' "$capability_context" | rg -q '^PRIVATE GEOFFREY CONTEXT$' || fail "Capability review must receive a prepared private context packet."
if printf '%s' "$capability_context" | rg -q 'does not need connected email or calendar context'; then
  fail "Capability review must not receive the empty-context notice."
fi
recommended_skill_context="$("$ROOT/bin/geoffrey" app-context --task recommend-skill)"
printf '%s' "$recommended_skill_context" | rg -q '^PRIVATE GEOFFREY CONTEXT$' || fail "Skill recommendation must receive a prepared private context packet."
rg -F 'Recommend my next step' "$ROOT/app/GeoffreyApp.swift" >/dev/null || fail "Improve Geoffrey needs an outcome-first recommendation action."
rg -F 'Recommend a skill for me' "$ROOT/app/GeoffreyApp.swift" >/dev/null || fail "Improve Geoffrey needs a focused skill recommendation action."
rg -F 'I already know which app I use' "$ROOT/app/GeoffreyApp.swift" >/dev/null || fail "Connection planning must keep app selection optional."
rg -F 'What do you want Geoffrey to handle more reliably?' "$ROOT/app/GeoffreyApp.swift" >/dev/null || fail "Skill creation must start with an owner outcome."
ok "Improve Geoffrey uses prepared context and outcome-first flows"

rg -F '@Published var runningTask: GeoffreyTask?' "$ROOT/app/GeoffreyApp.swift" >/dev/null || fail "Today actions must track the running task."
rg -F 'prominent: model.runningTask == .inbox' "$ROOT/app/GeoffreyApp.swift" >/dev/null || fail "Inbox must be highlighted while it is running."
ok "Today highlights the action that is actually running"

rg -F 'Choose one change. Geoffrey will use it next time.' "$ROOT/app/GeoffreyApp.swift" >/dev/null || fail "Briefing feedback must ask for one simple correction."
rg -F 'Button("Make it shorter")' "$ROOT/app/GeoffreyApp.swift" >/dev/null || fail "Briefing feedback needs one-tap corrections."
if rg -F 'Text("Choose one").tag("")' "$ROOT/app/GeoffreyApp.swift" >/dev/null; then
  fail "Briefing feedback must not require a menu selection."
fi
ok "Briefing feedback reduces owner effort"

rg -F 'What can I take off your plate?' "$ROOT/app/GeoffreyApp.swift" >/dev/null || fail "Ask Geoffrey needs an outcome-first empty state."
rg -F 'Ask about a task, decision, or problem you want off your plate' "$ROOT/app/GeoffreyApp.swift" >/dev/null || fail "Ask Geoffrey needs a visible composer prompt."
rg -F '.frame(height: 54)' "$ROOT/app/GeoffreyApp.swift" >/dev/null || fail "Ask Geoffrey needs a compact composer."
rg -F '.background(Color.white)' "$ROOT/app/GeoffreyApp.swift" >/dev/null || fail "Ask Geoffrey needs a clearly readable editor background."
rg -F '.foregroundStyle(.black)' "$ROOT/app/GeoffreyApp.swift" >/dev/null || fail "Ask Geoffrey needs readable editor text."
ok "Ask Geoffrey has a focused empty state and compact composer"

rg -F 'Image(systemName: "checkmark.circle")' "$ROOT/app/GeoffreyApp.swift" >/dev/null || fail "Briefing items need a mark-handled control."
rg -F 'app-complete-item' "$ROOT/app/GeoffreyApp.swift" "$ROOT/bin/geoffrey" >/dev/null || fail "Marking handled must persist in private memory."
rg -F 'completed-items.md' "$ROOT/bin/geoffrey" >/dev/null || fail "Handled items must be included in future Geoffrey context."
ok "Briefing items can be marked handled"

rg -F 'Button("Build this skill")' "$ROOT/app/GeoffreyApp.swift" >/dev/null || fail "A recommended skill needs a direct build action."
rg -F 'model.run(task: .buildSkill(recommendedSkillBuildBrief))' "$ROOT/app/GeoffreyApp.swift" >/dev/null || fail "The build action must use the recommendation as its build brief."
rg -F 'Button("Try this skill")' "$ROOT/app/GeoffreyApp.swift" >/dev/null || fail "A newly built skill needs a first-run action."
rg -F 'case let .ask(question), let .runSkill(question), let .buildSkill(question)' "$ROOT/app/GeoffreyApp.swift" >/dev/null || fail "A skill run must receive its approved request."
ok "Recommended skills can be built and used directly"

rg -F 'defaults write com.geoffrey.assistant geoffreyHome -string "$ROOT"' "$ROOT/scripts/install-mac-app.sh" >/dev/null || fail "App installation must pair the app with its matching engine."
ok "Installation pairs Geoffrey.app with its engine"

rg -F 'if task.isDailyBriefing {' "$ROOT/app/GeoffreyApp.swift" >/dev/null || fail "Only the daily briefing may replace the briefing dashboard."
rg -F 'self.latestBriefing = response' "$ROOT/app/GeoffreyApp.swift" >/dev/null || fail "Daily briefing must retain the dashboard state."
rg -F 'rateSection: {' "$ROOT/app/GeoffreyApp.swift" >/dev/null || fail "Briefing sections must support learning feedback."
rg -F '"Waiting on"' "$ROOT/app/GeoffreyApp.swift" >/dev/null || fail "Briefing must support waiting-item context."
rg -F '"Clarifications"' "$ROOT/app/GeoffreyApp.swift" >/dev/null || fail "Briefing must support clarification context."
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
