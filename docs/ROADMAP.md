# Geoffrey Desktop Roadmap

Updated: October 15, 2026

The detailed scope and proof standard are in [Desktop Release Record](DESKTOP-RELEASE.md).

## Phase 0: Recover a Trustworthy Baseline — Complete

- [x] Audit the earlier work instead of assuming it is valid.
- [x] Remove real-data screenshots and the stale private-beta app archive from the current branch.
- [x] Add explicit package allowlists and sensitive-material checks.
- [x] Establish one repeatable verification command.

## Phase 1: Build the Test Foundation — Complete

- [x] Isolate Mac checks from the developer's real home directory and Claude state.
- [x] Add behavioral tests for capability inventory, multi-account behavior, Outlook safety, graceful degradation, and migration secrecy.
- [x] Verify Claude distribution packages, Mac payloads, and code signatures.

## Phase 2: Preserve the Terminal Installation — Complete

- [x] Discover the legacy workspace, account registry, memory pointer, GitHub memory, and automation candidates.
- [x] Back up state before migration.
- [x] Write a secret-free migration manifest.
- [x] Install the app engine atomically in Application Support while leaving private state intact.

## Phase 3: Claude Conversation and Capability Center — Complete

- [x] Detect Claude CLI authentication and provide the supported login flow.
- [x] Capture and resume Claude session IDs.
- [x] Inventory skills, plugins, and MCP servers.
- [x] Prove a live authenticated two-turn conversation.
- [x] Add streaming, cancellation, readable tool activity, persistent visible history, and approved-change status.
- [x] Finish readiness, recommendation, and targeted repair experiences.

## Phase 4: Hybrid Automation — Pending

- [ ] Inventory and classify Dustin's existing social briefing automation.
- [ ] Surface imported routines and schedules in Geoffrey.
- [ ] Route cloud-compatible work to supported Claude cloud automation.
- [ ] Queue local-only work while the Mac is off and catch it up visibly.
- [ ] Record run history, failures, retry state, and owner approvals.

## Phase 5: Portable State and Security — Pending

- [ ] Define and implement the GitHub schema for memory, skills, connectors, automation manifests, and results.
- [ ] Move credentials and tokens to macOS Keychain.
- [ ] Prove sync success, visible failure, conflict handling, backup, and restore.
- [ ] Decide whether old Git history must be rewritten and rotate any exposed credentials if necessary.

## Phase 6: White-Glove UX — Pending

- [ ] Complete first-run setup without Terminal use.
- [ ] Finish add/test/repair/remove connection flows for multiple accounts.
- [ ] Add accessible states, useful empty states, understandable errors, and recovery actions.
- [ ] Test core workflows with a nontechnical user who has no developer assistance.

## Phase 7: Distribution and Dustin Pilot — Pending

- [ ] Implement an app-native signed updater with release notes and rollback.
- [ ] Sign with Developer ID, notarize, and verify Gatekeeper on a clean Mac.
- [ ] Publish a release candidate ZIP or DMG and checksum.
- [ ] Deliver the transition through Dustin's existing GitHub-based updater.
- [ ] Validate his memory, accounts, skills, connectors, and three-times-daily briefing end to end.
- [ ] Record acceptance evidence and only then mark the Dustin release complete.
