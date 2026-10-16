# Current Product Status

Updated: October 15, 2026

The current effort is the native Mac release for Dustin. The terminal interface is not the future product, but its state must be preserved. The authoritative scope, evidence, limitations, and release gate are in [Desktop Release Record](DESKTOP-RELEASE.md).

## Proven Now

- Native Mac app builds as Geoffrey `0.2.0` (build 2).
- The app installs its versioned engine in `~/Library/Application Support/Geoffrey/engine`.
- Legacy setup discovery covers the Geoffrey workspace, account registry, current-memory pointer, private GitHub memory, and likely automation files.
- Migration creates a permission-restricted local backup and a secret-free inventory without deleting or relocating the old state.
- Ask Geoffrey records and resumes Claude session IDs.
- Claude sign-in status and login flow are surfaced through the app.
- Capability inventory combines Claude skills, plugins, and MCP servers.
- Release packages use an explicit allowlist and pass sensitive-material checks.
- `./scripts/verify.sh` passes all current checks, including 7 behavioral tests and strict verification of the ad hoc signature.

## In Progress

- A readable persistent conversation with streaming, cancellation, tool activity, and approval moments.
- A capability center that explains what is ready, what needs attention, and what Geoffrey recommends.
- A hybrid automation center for cloud execution plus a queued local fallback.
- Portable GitHub state for approved skills, connector definitions, automation manifests, results, and recovery.
- Keychain-backed secret storage and connection repair.
- A signed, app-native updater that supersedes the initial legacy GitHub transition.

## Not Yet Proven

- The live two-turn Claude resume test, because the development Mac is not authenticated to Claude Code.
- Import and execution of Dustin's three-times-daily social briefing.
- Cloud execution while Dustin's Mac is off and queued catch-up for local-only work.
- Clean-Mac installation, Developer ID signing, notarization, Gatekeeper acceptance, and rollback.
- End-to-end migration against Dustin's actual machine.

## Readiness

This branch is a development milestone, not a Dustin release candidate. Dustin should not be involved until the release gate in the Desktop Release Record passes.
