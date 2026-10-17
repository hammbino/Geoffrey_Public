# Geoffrey Desktop Roadmap

Updated: October 17, 2026

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
- [x] Move account credentials and refresh tokens to macOS Keychain with transactional legacy migration.
- [x] Prove sync success, visible failure, conflict handling, backup, and isolated second-environment restore.
- [x] Audit old Git history and decide whether coordinated remediation is required.
- [ ] Coordinate the required history rewrite and rotate any credential that may have entered an old archive.

## Phase 6: White-Glove UX — Pending

- [x] Complete the native first-run setup guide without Terminal use, with saved progress and safe resume.
- [ ] Validate the full first-run sequence with clean-Mac and pilot-account acceptance.
- [x] Keep automation definition and approval inside the Mac app with plain-language safety boundaries.
- [x] Finish native add/test/repair/remove connection flows for multiple accounts.
- [ ] Validate add/test/repair/remove against Dustin's real Gmail and Outlook accounts.
- [x] Make first-run progress, connection recovery, and failed Ask Geoffrey requests accessible and directly retryable without relying on icons.
- [x] Preserve automation inventory on refresh failure and expose loading, retry, and workflow-specific accessible actions.
- [x] Preserve memory status on failed checks, distinguish unchecked recovery maps, and expose text progress and direct status retry.
- [ ] Complete accessible states, useful empty states, understandable errors, and recovery actions across the remaining core workflows.
- [ ] Test core workflows with a nontechnical user who has no developer assistance.

## Phase 7: Distribution and Dustin Pilot — Pending

- [x] Implement an app-native signed updater with release notes, strict publisher verification, and rollback.
- [x] Add a fail-closed, commit-bound release-gate report that requires owner-reviewed evidence for every Dustin criterion.
- [ ] Publish and exercise a Developer ID-signed, notarized update and rollback on a clean Mac.
- [ ] Sign with Developer ID, notarize, and verify Gatekeeper on a clean Mac.
- [ ] Publish a release candidate ZIP or DMG and checksum.
- [ ] Deliver the transition through Dustin's existing GitHub-based updater.
- [ ] Validate his memory, accounts, skills, connectors, and three-times-daily briefing end to end.
- [ ] Record acceptance evidence and only then mark the Dustin release complete.
