#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP="$ROOT/build/Geoffrey.app"
TEST_HOME="$(mktemp -d)"
TEST_MEMORY="$TEST_HOME/geoffrey-memory"
TEST_BIN="$TEST_HOME/bin"
trap 'rm -rf "$TEST_HOME"' EXIT

mkdir -p "$TEST_HOME/.geoffrey" "$TEST_HOME/Applications" "$TEST_MEMORY" "$TEST_BIN"
cp -R "$ROOT/memory-template/." "$TEST_MEMORY/"
ln -s "$APP" "$TEST_HOME/Applications/Geoffrey.app"
printf '%s\n' "$TEST_MEMORY" > "$TEST_HOME/.geoffrey/current-memory"
printf '{"accounts":[]}\n' > "$TEST_HOME/.geoffrey/accounts.json"
printf '%s\n' '#!/usr/bin/env bash' 'if [ "${1:-}" = "auth" ] && [ "${2:-}" = "status" ]; then echo "{\"loggedIn\":true}"; exit 0; fi' 'echo "2.1.0 (Claude Code)"' > "$TEST_BIN/claude"
chmod +x "$TEST_BIN/claude"

fail() {
  printf 'NO  %s\n' "$1"
  exit 1
}

ok() { printf 'OK  %s\n' "$1"; }

[ -x "$APP/Contents/MacOS/Geoffrey" ] || fail "Build Geoffrey.app before running this check."
ok "Geoffrey.app executable exists"

TEST_SWIFTC="$(command -v swiftc)"
for candidate in /opt/homebrew/opt/swift/*.xctoolchain/usr/bin/swiftc /usr/local/opt/swift/*.xctoolchain/usr/bin/swiftc; do
  if [ -x "$candidate" ]; then
    TEST_SWIFTC="$candidate"
    break
  fi
done
TEST_SDK="$(xcrun --sdk macosx --show-sdk-path)"
TEST_ARCH="$(uname -m)"
"$TEST_SWIFTC" -sdk "$TEST_SDK" -target "$TEST_ARCH-apple-macosx14.0" \
  "$ROOT/app/ClaudeStream.swift" "$ROOT/app/ClaudeStreamTests.swift" \
  -o "$TEST_HOME/claude-stream-tests"
"$TEST_HOME/claude-stream-tests" >/dev/null || fail "Claude stream events must be parsed safely."
ok "Claude stream parser handles partial text, tools, completion, and errors"

"$TEST_SWIFTC" -sdk "$TEST_SDK" -target "$TEST_ARCH-apple-macosx14.0" \
  "$ROOT/app/GeoffreyReadiness.swift" "$ROOT/app/GeoffreyReadinessTests.swift" \
  -o "$TEST_HOME/geoffrey-readiness-tests"
"$TEST_HOME/geoffrey-readiness-tests" >/dev/null || fail "Readiness states must produce the correct owner action."
ok "Readiness tests cover healthy, repair, and first-use states"

rg -F '.onSubmit(send)' "$ROOT/app/GeoffreyApp.swift" >/dev/null || fail "Chat must send when the owner presses Return."
rg -F 'TextField("Ask about a task, decision, or problem you want off your plate"' "$ROOT/app/GeoffreyApp.swift" >/dev/null || fail "Chat must use a native editable text field."
ok "Chat input is a native Return-to-send field"

rg -F '"--output-format", "stream-json"' "$ROOT/app/GeoffreyApp.swift" >/dev/null || fail "Claude responses must use streaming structured output."
rg -F '"--include-partial-messages"' "$ROOT/app/GeoffreyApp.swift" >/dev/null || fail "Claude responses must include partial messages."
rg -F 'arguments += ["--resume", resumeSessionID]' "$ROOT/app/GeoffreyApp.swift" >/dev/null || fail "Ask Geoffrey must resume its Claude session."
rg -F 'geoffreyClaudeSessionID' "$ROOT/app/GeoffreyApp.swift" >/dev/null || fail "Claude conversation identity must survive an app restart."
rg -F 'conversation.json' "$ROOT/app/GeoffreyApp.swift" >/dev/null || fail "The visible conversation must survive an app restart."
rg -F 'Button("New conversation")' "$ROOT/app/GeoffreyApp.swift" >/dev/null || fail "The owner needs a clear way to start a new Claude session."
rg -F 'Button("Stop")' "$ROOT/app/GeoffreyApp.swift" >/dev/null || fail "The owner needs to be able to stop a Claude request."
rg -F 'process.terminate()' "$ROOT/app/GeoffreyApp.swift" >/dev/null || fail "Stopping a request must terminate the active Claude process."
if rg -F 'Do not read files or call tools' "$ROOT/app/GeoffreyApp.swift" >/dev/null; then
  fail "General Geoffrey requests must not disable Claude files and tools."
fi
ok "Ask Geoffrey streams and preserves a resumable, cancellable conversation"

rg -F 'OperationalResultDisplay' "$ROOT/app/GeoffreyApp.swift" >/dev/null || fail "Operational results must use the structured renderer."
rg -F 'ResultEmptyState' "$ROOT/app/GeoffreyApp.swift" >/dev/null || fail "Operational results need an explicit no-items state."
rg -F 'Operational result feedback:' "$ROOT/app/GeoffreyApp.swift" >/dev/null || fail "Operational result sections must support learning feedback."
if rg -F 'Text(response.text)' "$ROOT/app/GeoffreyApp.swift" >/dev/null; then
  fail "Operational results must not fall back to a raw text wall."
fi
ok "Long operational results use structured UI"

capability_context="$(HOME="$TEST_HOME" "$ROOT/bin/geoffrey" app-context --task capability-review)"
printf '%s' "$capability_context" | rg -q '^PRIVATE GEOFFREY CONTEXT$' || fail "Capability review must receive a prepared private context packet."
if printf '%s' "$capability_context" | rg -q 'does not need connected email or calendar context'; then
  fail "Capability review must not receive the empty-context notice."
fi
recommended_skill_context="$(HOME="$TEST_HOME" "$ROOT/bin/geoffrey" app-context --task recommend-skill)"
printf '%s' "$recommended_skill_context" | rg -q '^PRIVATE GEOFFREY CONTEXT$' || fail "Skill recommendation must receive a prepared private context packet."
migration_result="$(HOME="$TEST_HOME" "$ROOT/bin/geoffrey" app-migrate)"
printf '%s' "$migration_result" | node -e 'let input = ""; process.stdin.on("data", chunk => input += chunk).on("end", () => { const migration = JSON.parse(input); if (migration.schema_version !== 1 || migration.state !== "migrated" || !migration.private_state.memory_repository.exists) process.exit(1); });' || fail "Legacy migration result is not valid."
[ -f "$TEST_HOME/.geoffrey/backups/pre-desktop-v1/accounts.json" ] || fail "Legacy account backup was not created."
[ -f "$TEST_HOME/.geoffrey/backups/pre-desktop-v1/current-memory" ] || fail "Legacy memory pointer backup was not created."
if rg -F 'refresh_token' "$TEST_HOME/.geoffrey/migration-v1.json" >/dev/null; then
  fail "Migration manifest must not contain account secrets."
fi
ok "Terminal-era state is backed up and inventoried without exposing secrets"
rg -F 'Recommend my next step' "$ROOT/app/GeoffreyApp.swift" >/dev/null || fail "Improve Geoffrey needs an outcome-first recommendation action."
rg -F 'Recommend a skill for me' "$ROOT/app/GeoffreyApp.swift" >/dev/null || fail "Improve Geoffrey needs a focused skill recommendation action."
rg -F 'I already know which app I use' "$ROOT/app/GeoffreyApp.swift" >/dev/null || fail "Connection planning must keep app selection optional."
rg -F 'What do you want Geoffrey to handle more reliably?' "$ROOT/app/GeoffreyApp.swift" >/dev/null || fail "Skill creation must start with an owner outcome."
capabilities="$(HOME="$TEST_HOME" PATH="$TEST_BIN:$PATH" "$ROOT/bin/geoffrey" app-capabilities)"
printf '%s' "$capabilities" | node -e 'let input = ""; process.stdin.on("data", chunk => input += chunk).on("end", () => { const items = JSON.parse(input); if (!Array.isArray(items) || !items.some(item => item.type === "skill" && item.enabled) || items.some(item => !item.state || !item.repair)) process.exit(1); });' || fail "Capability inventory must return actionable Geoffrey readiness states."
rg -F 'Label("Available in Geoffrey"' "$ROOT/app/GeoffreyApp.swift" >/dev/null || fail "Improve Geoffrey must show available Claude capabilities."
rg -F 'Label("Geoffrey readiness"' "$ROOT/app/GeoffreyApp.swift" >/dev/null || fail "Improve Geoffrey must summarize readiness before recommending new capabilities."
rg -F 'func performReadinessAction(' "$ROOT/app/GeoffreyApp.swift" >/dev/null || fail "Each readiness problem must route to an owner action."
rg -F 'func repairCapability(' "$ROOT/app/GeoffreyApp.swift" >/dev/null || fail "Disabled or disconnected Claude capabilities need repair actions."
rg -F 'Button(repairTitle)' "$ROOT/app/GeoffreyApp.swift" >/dev/null || fail "Capability repair must be available in the interface."
rg -F 'func openGitHubLogin()' "$ROOT/app/GeoffreyApp.swift" >/dev/null || fail "GitHub portability needs an in-app connection path."
ok "Improve Geoffrey explains readiness and routes targeted repairs"

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

rg -F 'engine.installing' "$ROOT/app/GeoffreyApp.swift" >/dev/null || fail "App installation must stage its version-matched engine atomically."
rg -F '.geoffrey-engine-version' "$ROOT/app/GeoffreyApp.swift" >/dev/null || fail "App installation must version its embedded engine."
rg -F '["app-migrate"]' "$ROOT/app/GeoffreyApp.swift" >/dev/null || fail "The app must migrate the terminal-era state automatically."
ok "Installation uses a versioned self-contained engine and automatic migration"

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

test_status="$(HOME="$TEST_HOME" PATH="$TEST_BIN:$PATH" "$ROOT/bin/geoffrey" app-status)"
printf '%s\n' "$test_status" | rg -q '^claude\tready$' || fail "Geoffrey must verify Claude authentication, not only CLI installation. Status was: $test_status"
printf '%s\n' "$test_status" | rg -q '^app\tready$' || fail "Geoffrey engine is not ready for the app. Status was: $test_status"
ok "Geoffrey engine reports ready"

accounts="$(HOME="$TEST_HOME" "$ROOT/bin/geoffrey" app-accounts)"
printf '%s' "$accounts" | node -e 'let input = ""; process.stdin.on("data", chunk => input += chunk).on("end", () => { const accounts = JSON.parse(input); if (!Array.isArray(accounts) || accounts.some(account => !account.id || !account.email || !account.calendar?.state)) process.exit(1); });' || fail "Account-health data is not valid."
ok "Account-health data is valid"

"$ROOT/scripts/check-release-safety.sh" "$APP" >/dev/null || fail "Built application contains unsafe release material."
ok "Built application excludes private and development-only material"

printf 'Geoffrey Mac app check passed.\n'
