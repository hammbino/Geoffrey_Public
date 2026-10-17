# Geoffrey Desktop Roadmap

Updated: October 16, 2026

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

## Phase 4: Hybrid Automation — In Progress

- [x] Discover and classify portable workflows and likely terminal-era automation files without changing schedules.
- [x] Surface imported routines and schedules in Geoffrey with cloud, Mac-required, and review states.
- [x] Add an in-app create, edit, review, draft, and explicit-approval flow for portable workflow definitions.
- [x] Add a guided Claude Routine handoff with connector review, cadence confirmation, and owner-reviewed run evidence.
- [x] Add a validated, no-merge GitHub result inbox and an in-app Check results action for connected Claude Routines.
- [ ] Route cloud-compatible work to supported Claude cloud automation.
- [x] Queue missed occurrences of approved local-only work safely and show the queue count.
- [x] Execute approved queued local work in read-only mode when Geoffrey returns and show its result.
- [x] Record local run history, failures, retry state, and owner approvals.
- [ ] Verify cloud run history, failures, and routine health through a supported Claude interface.
- [ ] Validate and bind Dustin's actual three-times-daily social briefing during release-candidate acceptance.

## Phase 5: Portable State and Security — In Progress

- [x] Define and implement the portable automation manifest, bounded history, and owner-ready result subset.
- [x] Complete the GitHub schema for approved skills, connector definitions, and restore metadata.
- [x] Surface GitHub sync success, local-only state, credential blocks, failures, and conflict recovery inside the app.
- [ ] Move credentials and tokens to macOS Keychain.
- [ ] Prove sync success, visible failure, conflict handling, backup, and restore.
- [ ] Decide whether old Git history must be rewritten and rotate any exposed credentials if necessary.

## Phase 6: White-Glove UX — Pending

- [ ] Complete first-run setup without Terminal use.
- [x] Keep automation definition and approval inside the Mac app with plain-language safety boundaries.
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
