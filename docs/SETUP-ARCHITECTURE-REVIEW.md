# Setup and architecture review — October 19, 2026

Implementation follow-up: the findings below describe the reviewed baseline. The subsequent fixes and current verification boundaries are recorded in `CURRENT-STATUS.md` under “Setup stabilization — local build 22.”

Geoffrey's scope has grown beyond the reliability of its basic setup. The main architectural problem is coupling: the native app still drives a large terminal-oriented engine, and a single refresh coordinates setup, account health, migration, capabilities, automations, backup, and recovery inventory. More features and more source-text checks will not resolve this.

This review covers the current working tree, including existing uncommitted fixes. No application code was changed. All 58 Node tests passed. Additional isolated probes reproduced the dependency failure, backup recovery loop, and process-output failure below. The review did not perform live OAuth, touch real credentials, launch the owner's app, or certify a downloaded release on a clean Mac.

## Findings, in priority order

### 1. P1 — The native package cannot bootstrap its required runtimes

Evidence: `scripts/build-mac-app.sh:96`, `bin/geoffrey:2265`, `app/GeoffreyApp.swift:3730`, `app/GeoffreyApp.swift:3819`.

The bundle copies the shell/JavaScript engine but does not include Node, Claude, or GitHub CLI. Status and login invoke those external commands. Missing Claude routes to a message to reinstall a release containing its helper, but the current builder does not package that helper. GitHub login similarly attempts `gh` without provisioning it. Engine readiness checks only whether `bin/geoffrey` is executable.

Reproduction: invoked the existing packaged engine in a disposable HOME with system-only PATH. `app-status` exited 0 and reported `app ready`; `app-migrate` exited 127 with `node: command not found`. This models missing developer-installed tools; it is not a full clean-Mac installation test. The app's normal PATH additionally includes Homebrew directories, which can hide the omission on a developer Mac. Its fixed PATH also excludes user-local executable directories.

Required correction: define one supported runtime installation/discovery contract, implement it in the actual download, and verify every required executable before marking the helper ready. Reinstallation guidance must lead to a package that can fix the missing dependency.

### 2. P1 — A failed initial GitHub backup has no working retry path

Evidence: `app/GeoffreyApp.swift:3460`, `bin/geoffrey:1109`, `geoffrey-mcp/bin/memory-sync.js:226`, `app/GeoffreySetup.swift:34`.

Saving the local pointer before remote creation is a useful fix. However, when remote creation fails before adding `origin`, the UI tells the owner to use Sync now. Sync only reports `local_only` when `origin` is absent; it cannot create the remote. GitHub sign-in only authenticates. Starting memory creation again refuses the populated folder. Meanwhile, setup considers GitHub authentication plus a local memory path sufficient to complete the backup and memory steps.

Reproduction: ran the real memory-creation command with an isolated authenticated fake GitHub publisher that fails repository creation. Local memory survived. Two subsequent real `app-sync` calls both exited 0 with `state: local_only`; neither repaired the missing backup. Existing memory-setup tests stop after verifying the saved pointer and never exercise this advertised recovery.

Required correction: provide an idempotent backup operation for existing local memory, including create/link/push recovery. Represent local readiness, authentication, and verified backup separately. Preserve the current protection against overwriting existing memory.

### 3. P1 — The common command runner can deadlock on ordinary output

Evidence: `app/GeoffreyApp.swift:3824–3857`; the account-connection runner repeats the wait-before-read pattern at `app/GeoffreyApp.swift:3219`.

The runner waits for a child to exit before draining stdout and stderr. Once either pipe fills, the child waits for the parent to read while the parent waits for the child to exit. Calls without deadlines can hang indefinitely; calls with deadlines can kill otherwise successful work. Termination also has no bounded escalation if the child ignores it.

Reproduction: compiled the exact current `run` method in an isolated Swift executable. A successful child producing 1 MiB of stdout, with a one-second deadline, returned status 124 and only 65,536 bytes. This proves the pipe problem without relying on a provider or live account. It does not establish that this caused every reported setup failure.

Required correction: drain both streams while the child runs, retain exit status and error output independently, and make cancellation/deadlines bounded. Test the production runner itself with large stdout, large stderr, failure, cancellation, and a child that resists termination.

### 4. P2 — Setup waits on unrelated refresh work

Evidence: `app/GeoffreyApp.swift:2706–2734`.

Every refresh runs eight commands sequentially. Migration and automation queuing have no deadline; six subsequent commands each allow 30 seconds. Results are published only after all commands finish. A slow capability inventory or recovery-map check can therefore delay already-known setup/account results. Refresh also performs migration and queue writes, so it is not simply a status read.

Required correction: make setup status small and independently publishable. Run migration at an explicit startup/version boundary. Load capabilities, automation inventory, and recovery details when their screens need them. Adding parallelism to all eight commands would retain unnecessary coupling and needs care around shared-file writes.

### 5. P1 validation gap — Passing checks do not establish a working setup journey

Evidence: `scripts/check-mac-app.sh:12–18`, `scripts/check-mac-app.sh:101–116`, `geoffrey-mcp/test/memory-setup.test.mjs`, `app/GeoffreySetupTests.swift`.

The Mac check contains 111 lines beginning with `rg` or `if rg`. Some are useful packaging/policy checks, but many claim behavior from the presence of strings: finding `process.terminate()` does not prove cancellation; finding `conversation.json` does not prove restart persistence. The fixture begins with memory already selected, stubs Claude as authenticated, and inherits the host's tools. The script builds/inspects the app and tests helper logic, but does not drive its actual setup UI from first launch to first useful response.

There are valuable behavioral tests for rollback, sync conflicts, restore validation, and credentials. Keep them. The missing layer is interaction between the app, subprocesses, installed artifacts, and persisted state. The native Keychain dummy check is also outside default verification, so mocks alone cannot validate that OS boundary. Release documentation correctly distinguishes local verification from real acceptance; more release paperwork will not supply the missing executable tests.

## Simplification direction

1. Pause expansion of automations, cloud-routine bridging, capability repair, and skill generation until the basic journey is reliable. Preserve existing user data and compatibility.
2. Aim for launch → Claude sign-in → one account → local memory → useful briefing. Recommend GitHub backup after first value, or make its mandatory setup/recovery complete if it must remain a product requirement.
3. Keep one tested process runner and one typed setup result. Stop independently interpreting free-form status strings in setup, sidebar, and capability readiness. Avoid introducing a generic workflow framework.
4. Separate the desktop command entry point from the 3,579-line legacy shell CLI incrementally. Keep the existing providers and credential protections. Extract orchestration from the 3,867-line app file only where doing so enables tests of real behavior.
5. Keep Keychain protection, safe restore, and signed-update verification. Reduce when these systems participate in setup rather than deleting protections to reduce line count.

## Minimum evidence before another setup-ready claim

- A packaged installation on a fresh macOS user/VM with no developer tools or preexisting Geoffrey state reaches the first useful response.
- The production app model and runner pass deterministic journeys for successful setup, cancelled login, wrong-account reconnect, failed remote creation followed by successful retry, and restart during setup. Use fake external services at process/network boundaries, not replacements for the setup logic under test.
- A broken account and a missing backup cannot produce a completed/healthy state that contradicts the affected screen.
- Actual UI automation exercises the visible setup controls and verifies progress, retry, dismissal, and relaunch. Source-text checks remain labeled as structural checks.
- A separate controlled native integration stage validates the packaged Keychain helper and a limited real OAuth journey. Keep normal unit tests isolated from real credentials.

Fix the runtime contract and backup recovery first, then the shared runner and refresh coupling. Establish the journey tests alongside those changes before broad structural refactoring.
