# Geoffrey Desktop Release Record

Updated: October 17, 2026

This is the authoritative record for the Mac desktop release being prepared for Dustin. It defines the intended product, what is already proven, what remains unproven, and the gate Geoffrey must pass before Dustin is asked to update.

## Desired End Result

Geoffrey is a native, approachable Mac application that gives a nontechnical person the power of their existing Claude Code setup without requiring them to understand terminals, skills, MCP servers, connectors, or automation infrastructure.

The finished Dustin release must:

- replace the terminal interface for normal use;
- preserve Dustin's existing accounts, memory, GitHub-backed history, skills, connectors, and automations;
- use Claude Code as the intelligence and tool runtime rather than recreating it;
- expose capabilities in plain language and recommend useful additions with explicit approval;
- support more than one Gmail or Microsoft/Outlook account;
- bring Dustin's existing three-times-daily social briefing into Geoffrey;
- use cloud execution when the workflow can run safely without the Mac, and queue or catch up locally when it cannot;
- keep durable, non-secret state in the owner's GitHub repository so the owner is not trapped in Geoffrey;
- keep credentials and tokens out of GitHub and release packages;
- install and update simply as a Mac app; and
- prove each release with repeatable checks before it is handed to Dustin.

The old terminal interface does not need to remain part of the product. The data and configuration created by that version do.

## Product Boundary

| Layer | Responsibility |
| --- | --- |
| Geoffrey Mac app | Conversation, briefings, capability discovery, connection health, approvals, setup, updates, and understandable error recovery. |
| Claude Code | Reasoning, skills, MCP servers, connectors, and tool execution. Geoffrey wraps this power instead of replacing it. |
| Local Geoffrey state | Account registry, current memory pointer, migration record, and local-only workflow dependencies. |
| Owner's private GitHub memory repository | Portable memory, approved skills and workflow definitions, feedback, non-secret configuration, automation manifests, and useful results. |
| Cloud automation | Preferred for workflows whose inputs and tools are available in Claude's supported cloud environment. |
| Local automation queue | Used when a workflow requires the Mac, a local file, or a local-only connector. Missed work should be queued and caught up after the Mac returns. |
| macOS Keychain | Account OAuth details and refresh tokens live in versioned generic-password items. The local registry is secret-free; portable restore requires sign-in again. |

## Dustin Upgrade Path

Dustin should not be involved until the release candidate passes the release gate.

The planned transition is:

1. Use the existing GitHub-based update path from Dustin's terminal installation to deliver the desktop release candidate.
2. Install `Geoffrey.app` and let it place its versioned runtime in `~/Library/Application Support/Geoffrey/engine`.
3. Before changing state, create a permission-restricted local backup at `~/.geoffrey/backups/pre-desktop-v1`.
4. Discover the existing `~/Geoffrey` workspace, `~/.geoffrey/accounts.json`, current-memory pointer, private GitHub memory repository, and likely automation files.
5. Write a secret-free migration inventory to `~/.geoffrey/migration-v1.json` and continue using the existing private state in place.
6. Validate the desktop app against Dustin's real configuration. Keep the old checkout recoverable until this validation succeeds.
7. After the transition is proven, publish through the app's signed update feed. The client and release tooling are implemented, but the first Developer ID and notarized end-to-end update still requires clean-Mac acceptance.

Migration is deliberately non-destructive: it inventories and preserves state rather than moving or deleting Dustin's files.

## Completed and Proven

### Release safety

- Removed 12 tracked screenshots containing real recipient information from the current branch.
- Removed the stale 98 MB private-beta app archive from the current branch.
- Changed the Mac app builder to an explicit payload allowlist.
- Added a release-safety checker that blocks credentials, token/account files, environment files, Git metadata, screenshots, recipient material, and development artifacts.
- Rebuilt the Claude distribution archives with the same safety exclusions.

The current tree and packages pass the safety checker, but the metadata-only October 17 audit confirms 12 recipient-media blobs totaling 4,753,953 bytes and two private app-archive blobs totaling 141,889,040 bytes remain reachable in Git history. No known credential-bearing filenames remain reachable. A coordinated rewrite is required before broader distribution, and any credential known to have entered an opaque archive must be rotated. The required procedure is recorded in [Git History Remediation Decision](HISTORY-REMEDIATION.md); historical removal has not been claimed.

### Automatic migration

- Added a legacy-state discovery and migration command.
- Added a `0600` pre-migration backup and secret-free migration manifest.
- Made the app install or refresh its embedded engine atomically in Application Support.
- Kept private memory and account data outside the app bundle so replacing the app does not erase the owner state.

### Claude runtime and capability visibility

- General requests and skill building may use Claude tools and files; prepared read-only views remain constrained.
- Ask Geoffrey uses Claude's streaming JSON output, displays partial text, records the returned Claude session ID, and resumes that session for later turns.
- The owner can stop an active Claude process, start a new conversation, and see plain-language status when Geoffrey is thinking, reading approved information, checking the web or a connected account, or preparing an approved change. A failed request retains a direct retry action without adding a duplicate owner message to the visible conversation.
- The visible conversation persists across app restarts in Application Support with owner-only file permissions.
- The app detects Claude CLI authentication and can start Claude's supported login flow.
- Improve Geoffrey inventories available user, private, and bundled skills plus installed Claude plugins and MCP servers.
- Improve Geoffrey summarizes the readiness of Claude, multiple email/calendar accounts, private memory, GitHub portability, and Claude capabilities before recommending expansion.
- Disabled plugins can be explicitly enabled, MCP login failures can be reconnected, pending approvals receive precise guidance, unhealthy accounts route to reconnect, and GitHub has an in-app browser login path.

### Hybrid automation foundation

- Added a secret-free automation manifest under private GitHub-backed memory and documented which fields are portable.
- Added read-only discovery for declared workflows and terminal-era files whose names indicate briefings, schedules, routines, or automations.
- Added safe routing into `cloud`, `local`, or `review` based on declared local paths, cloud compatibility, approval, and capability readiness.
- Added an Automation Center that shows cadence, route, source, queued runs, and the approval boundary in plain language.
- Added an in-app sheet to create or edit a recurring workflow, review its purpose and read-only task, choose cloud or local execution, set one to three daily times, and save a disabled draft or an explicitly approved definition.
- Portable workflow saves are atomic and owner-only, reject common credential forms before writing, preserve imported source identity to prevent duplicate candidates, and use the existing private-memory sync path after a successful save.
- An approved cloud definition remains `not_connected`; the review sheet explicitly states that saving it does not create a Claude Routine.
- Added a guided Claude Routine handoff with a copyable approved brief, explicit cadence confirmation, and mandatory least-privilege review because Claude includes connected tools by default and autonomous runs can use their write capabilities.
- A clean `claude.ai` Routine link records `connected`, not active. “Cloud run reviewed” requires a separate Claude session link plus the owner's confirmation that they opened the Run now session and inspected the actual result.
- Routine API bearer tokens are never requested or stored. Only non-secret Claude links and owner-review timestamps enter private GitHub-backed memory.
- The Routine brief includes a strict result-envelope contract and deterministic workflow-specific `claude/` branch. Geoffrey can fetch that exact branch from the existing private memory remote and expose Check results without requiring a Routine API token.
- Cloud import never checks out or merges the result branch. It reads only bounded JSON files in the workflow inbox, validates workflow identity, timestamps, source, status, and size, rejects malformed or mismatched envelopes, redacts common credential forms, deduplicates imports, and copies accepted output into normal portable results and bounded history.
- Replaced silent app-memory sync with a machine-readable status contract surfaced on the Memory screen. Owners can see backed-up, local-only, conflict, credential-blocked, and attention states, choose Sync now, and read a concrete recovery step.
- Sync fast-forwards remote-only updates, cleanly rebases independent local/remote work, and pushes the resulting branch. If both sides changed the same content, Geoffrey aborts the rebase immediately and verifies that the original local branch is restored instead of guessing which memory wins.
- Before any automatic memory commit, Geoffrey blocks common token/key/password patterns, credential-bearing filenames, symlinks, and files beyond its inspection limit. The file stays on the Mac, no push occurs, and the safety block appears in Memory.
- Added a bounded, duplicate-safe local missed-run queue for enabled workflows with explicit approval. Queue creation does not execute Claude or touch a cloud schedule.
- Added explicit Run queued, Run now, Retry, and Open last result actions for approved local work.
- Local execution uses Claude's `plan` permission mode, refuses unapproved and cloud-routed workflows before starting Claude, and never uses a permission-bypass flag.
- Successful results and bounded run history are written to private GitHub-backed memory; failures remain in the local queue for retry and are also recorded portably.
- Common credential forms are redacted before portable results or errors are written.
- Added `memory/portable-state.json`, a versioned recovery schema for approved private-memory skills, non-secret email/calendar and Claude connection definitions, repository metadata, content hashes, and explicit sign-in-again steps. The Memory screen reports drift and updates this map only on an owner action before using the existing guarded GitHub sync.
- Added an in-app guided restore that accepts a private GitHub owner/repository name, clones with an isolated Git template into a fresh staging folder, validates the clean checkout, tracked files, recovery schema, and every approved skill hash, rejects credential-bearing files, symbolic links, nested repositories, and checkout-time artifacts, restricts restored permissions to the owner, then atomically selects the verified memory. A failed pointer update removes the staged clone. It never recreates account credentials or connected-account state.
- Moved OAuth client details and refresh tokens from the local account registry into versioned macOS Keychain items. New and reconnected accounts write secrets over stdin rather than process arguments; existing plaintext registries migrate transactionally, the legacy backup is scrubbed only after success, and failure leaves the original state intact. Removal deletes both the registry entry and its Keychain item. The Connections screen shows whether the credential is protected or needs secure sign-in.
- Added an explicit per-account connection test that verifies the provider mailbox identity endpoint and read-only calendar access without reading messages. The test is bounded to 30 seconds in the app, updates only that account's visible health, returns no credentials, and routes failures to reconnect, network retry, timeout retry, or refresh guidance.
- Replaced the Settings update placeholder with a native signed-update client. It verifies an exact Ed25519-signed manifest, HTTPS responses and redirects, archive size and SHA-256, safe extraction paths, the expected bundle/version, and the same Apple Developer ID team both before and during replacement. It shows signed release notes, checks quietly once per day, keeps the previous signed app for rollback, relaunches the preserved app after a helper failure, and never places private memory or Keychain state in the package.
- Added release tooling that refuses to create a production update without an external owner-only update key, a hardened Developer ID signature, Apple notarization and stapling, reviewed release notes, and a non-overwriting output directory. Ad-hoc development builds intentionally report that signed updates are unavailable.
- A single-run lock prevents overlapping local automations from racing queue/history writes; locks older than the bounded execution window are recoverable.
- Cloud setup routes to Claude Routines. A declared `active` state is downgraded to `needs_verification` unless the portable workflow also has a `verified_at` timestamp.
- Verified from Anthropic's current documentation that supported off-Mac execution exists through Claude Code routines and Claude Managed Agents scheduled deployments. Managed Agents scheduling is beta and requires an agent, environment, per-run initial event, POSIX cron expression, IANA timezone, credentials/vault configuration, and appropriate budgets and permissions. Geoffrey does not silently provision those resources.

Primary references: [Claude Code routines](https://code.claude.com/docs/en/routines), [Claude Managed Agents scheduled deployments](https://platform.claude.com/docs/en/managed-agents/scheduled-deployments), and [secure deployment guidance](https://platform.claude.com/docs/en/managed-agents/secure-deployment).

### Native first-run setup

- Added a native setup guide that automatically appears once when the installed app finds incomplete setup and remains available through Continue setup after dismissal.
- The guide derives one ordered next action from locally observed state: Geoffrey helper, Claude sign-in, first email/calendar account, private GitHub backup, then private-memory create or restore.
- Completed steps are never reset by canceling the guide. Transitions into the existing secure account, memory-create, and verified-memory-restore sheets occur only after the guide closes.
- The setup-state model has isolated tests for fresh install, staged progress, an existing local memory with missing backup authentication, and the complete state.
- The live macOS accessibility tree exposes each of the five setup steps separately, with stable identifiers, explicit complete/next/not-complete labels, and the matching explanatory detail instead of one merged status block.

Live authentication evidence on October 15, 2026:

- Claude Code `2.1.301` authenticated successfully through Claude's supported browser flow.
- Turn one created a session and stored a harmless test code.
- Turn two resumed the same session ID and returned the correct test code, proving context continuity.
- A separate request using Geoffrey's exact `stream-json`, partial-message, verbose, model, and permission flags emitted the expected session, partial-text, assistant, and final-result events.

### Repeatable verification

Run the complete local gate from the repository root:

```bash
./scripts/verify.sh
```

The current verified result is:

- shell syntax checks: pass;
- JavaScript syntax checks: pass;
- behavioral tests: 44 passed, 0 failed;
- isolated Claude stream parser tests: pass for session identity, partial text, tool activity, final results, structured failures, and non-JSON diagnostics;
- Ask Geoffrey recovery checks: pass for a direct failed-request retry that reuses the original task without duplicating the owner message;
- isolated readiness tests: pass for all-ready, multi-account repair, signed-out, first-use, empty-inventory, and capability-attention states, plus failed/partial/duplicate/timeout setup rejection and successful-empty versus failed capability inventory;
- isolated first-run tests: pass for helper repair, Claude, email, GitHub, existing-memory backup, completion, and safe progress preservation;
- targeted account-health tests: pass for secret-free email/calendar recovery state, missing Keychain credentials, and removed-account refusal;
- isolated connection-refresh tests: pass for successful replacement, failure preservation, timeout preservation, and targeted retry guidance;
- connection accessibility checks: pass for a separately addressable refresh failure and retry action, explicit icon-only control labels, and decorative status-icon suppression;
- isolated memory-status tests: pass for failed/malformed/timeout reads, structured sync-failure reports, wrong-shape rejection, and honest unchecked recovery-map labels;
- isolated automation tests: pass for cloud-capable, active-cloud, Mac-required, and review labels, failed/malformed/unsupported/timeout inventory preservation, and successful empty-list recovery;
- Claude package safety/currentness: pass;
- Mac app build and payload safety: pass;
- isolated Mac app checks using a temporary home and fake Claude authentication: pass; and
- strict code-signature verification: pass using an ad hoc signature.
- history exposure report: `status=rewrite_required`, with counts only and no recipient filenames or contents printed.
- Dustin release-gate report: `blocked`; the checker fails closed on unresolved history, a dirty or mismatched commit, a missing evidence file, or any acceptance item without an owner-reviewed reference.

The `0.14.0` build also packages Geoffrey's revised illustrated app icon at native Mac sizes and uses that same bundled identity in a visible sidebar header. The original portrait source remains preserved, and an automated Mac check prevents the in-app brand and packaged icon from drifting apart. The built app was inspected live at its minimum supported window size in the prior UI slice: the 220-point sidebar shows the full Geoffrey name, “Your AI chief of staff” description, and every navigation label without clipping. The rebuilt Settings screen was inspected live in dark mode: version, update action, verification explanation, app folder, model choice, and help text were legible and unclipped, and the ad-hoc build visibly changed to “Signed updates will become available with Geoffrey’s release build” without opening a network-dependent installer. The release-notes sheet still requires a dedicated signed-feed visual acceptance pass.

The rebuilt incomplete-setup state was also inspected in the exact built app in dark mode. The guide automatically appeared, showed accurate progress and the next step across all five setup areas, fit without clipping, and returned to Today with a visible Continue setup action after dismissal. Its live accessibility tree was inspected after the row fix and exposed five distinct labeled setup-step elements. The rebuilt Connections empty state and its no-message-read test boundary were also legible in the exact app. Populated Test connection results remain fixture-backed until real-account acceptance. Live provider sign-in, new-memory creation, and clean-Mac resume remain pilot acceptance rather than locally claimed release evidence.

The behavioral tests cover automation discovery, secret exclusion, cloud/local/review routing, bounded missed-run queuing, approval enforcement, portable draft/approval saves, imported-candidate deduplication, atomic rejection of credential-bearing definitions, safe Routine-link validation, unverified connected state, owner-reviewed run evidence, successful local execution, failure and retry, concurrency refusal, result portability, credential redaction, validated cloud-envelope import, no-checkout/no-merge branch isolation, import deduplication, malformed-envelope rejection, missing-branch handling, memory commit/push success, remote fast-forward, clean divergence rebase/push, conflict abort with local preservation, local-only state, credential-blocked sync, isolated second-environment restore, checkout-hook isolation, failed-pointer rollback, transactional Keychain writes, legacy secret migration, failed-migration preservation, multi-account migration rollback, capability inventory aggregation and repair classification, the multi-account MCP contract, Outlook filtering and free-text handling, recipient-label safety/no-send behavior, missing-category degradation, migration without token leakage, Claude stream parsing, and owner-facing readiness decisions. A reversible native macOS proof also created, updated, read, and deleted a uniquely named dummy Keychain item while passing the value through stdin rather than command arguments. The isolated Mac check saves a draft through the public command, proves that it round-trips without becoming enabled, and proves that a Routine link remains `connected` with no verification timestamp until a reviewed run is recorded. The built Ask Geoffrey, Improve Geoffrey, and Connections interfaces were previously inspected visually in dark mode for hierarchy, legibility, clipping, and action clarity. The rebuilt Automation Center empty state and add/review sheet were inspected in the live app on October 16 for hierarchy, required fields, schedule controls, private-memory destination, and explicit approval clarity. The Memory setup state was visually inspected after the sync-status UI was added. The populated recovery-map state was then inspected in a disposable profile at the minimum window size: its status, counts, credential boundary, action, recovery guidance, and memory path were visible without clipping, and the owner action visibly advanced the state from `needs_update` to `ready`. The first-use Memory choice and guided restore sheet were also inspected in an isolated 0.12.0 app at the minimum window size; restore/start-fresh choices, overwrite protection, GitHub prerequisite, token warning, destination, and verification action were legible and unclipped. Populated Git sync and conflict states remain fixture-backed until a dedicated visual fixture or Dustin-state acceptance pass. The cloud setup sheet compiles and is covered by accessibility-copy and behavior checks; its populated visual acceptance remains part of the fixture-backed or Dustin-state pass.

Automation inventory refresh preserves workflows and counts when the command fails, times out, returns malformed JSON, or reports an unsupported schema. The screen exposes checking and retry states, suppresses the empty-state claim until a successful check, and identifies repeated card actions by workflow. Run status is readable as text instead of depending on an icon. These changes have automated logic and build coverage; real populated-workflow failure-state and VoiceOver acceptance remain unproven.

Memory status refresh is bounded and preserves prior backup and recovery-map information after failed reads, with a visible stale-status warning and a separately accessible retry action. Recovery maps distinguish unchecked state from needing an update and suppress unchecked counts. Backup and recovery-map writes cannot overlap each other or status refresh. Progress has text labels and the Memory page scrolls for longer recovery guidance. Automated model and Mac build checks cover this slice; real pilot failure-state and VoiceOver acceptance remain outstanding.

Setup and capability refresh now use bounded checks and preserve last-known state after failed or malformed responses. A failed setup check exposes a global retry banner, cannot automatically reopen first-run setup, and does not replace saved health. Improve Geoffrey distinguishes checking, successfully empty, and failed capability inventory. Stale readiness is identified, repair controls are disabled until the relevant checks recover, repeated repair actions include the affected capability in their accessible name, and repair progress has text. Automated contract checks and builds cover these states; real pilot failure-state and VoiceOver acceptance remain outstanding.

A disposable, source-matched SwiftUI fixture was inspected live in light mode on October 17. Its initializer used only synthetic setup, capability, backup-conflict, and failed-refresh state; engine installation, conversation loading, and startup refresh were skipped. The setup warning no longer overlaps the sidebar or content. Memory exposed a separately addressable retry, an honest unchecked recovery map, preserved conflict guidance, and a scroll-reachable memory-folder action. Automations exposed a separate retry without the no-workflows empty claim. Improve Geoffrey exposed retained capability data, stale-readiness guidance, disabled repair, and a separate capability retry. This is fixture layout/accessibility-tree evidence, not real account behavior, a production-app end-to-end pass, or a VoiceOver user acceptance result.

## Honest Limitations and Remaining Work

The following are not complete and must not be presented as finished:

- **Cloud automation:** discovery, classification, local queueing/execution, portable local results, retry history, guided Routine connection/evidence, and a validated no-merge cloud result importer are implemented. A real Routine still must be created in Claude, run while the Mac is off, publish the specified envelope, and be validated against Dustin's actual briefing. Geoffrey currently requires the visible Check results action; background polling and supported noninteractive Routine management are not implemented.
- **Secrets:** Keychain-backed account storage, transactional legacy migration, failure preservation, visible repair state, and sign-in-again recovery are implemented and synthetically proven. Dustin's real account registry still requires pilot acceptance; credentials are intentionally not exported or restored across Macs.
- **GitHub portability:** workflow definitions, results, bounded run history, approved-skill hashes, non-secret connector definitions, and restore metadata use private memory. Visible sync status, retry, clean-divergence reconciliation, conflict abort/preservation, credential blocking, recovery-map drift detection, and guided second-environment restore are implemented and tested. A real private-GitHub restore on a clean pilot Mac remains part of release-candidate acceptance.
- **Connections:** native add, bounded per-account test, reconnect, remove, accessible loading/failure/empty states, separately addressable retry and management controls, last-known-state preservation, and health explanations exist. Secret-free failure states and accessibility semantics are automated; populated results and real Gmail/Outlook behavior still require clean-Mac and Dustin-state acceptance testing.
- **First run:** the native ordered guide, automatic first incomplete-state presentation, safe dismissal/resume, and transitions to existing native setup flows are implemented and locally inspected. A complete clean-Mac run using pilot Claude, email, GitHub, and private-memory state remains acceptance work.
- **Updates:** the legacy GitHub updater can deliver the first desktop transition. The native signed client, release notes, automatic check, verified replacement helper, and rollback path are implemented, but no production Developer ID/notarized update feed has been published or exercised end to end. That real update and rollback acceptance remains required before the native path is called release-ready.
- **Distribution:** the app is ad hoc signed only. Developer ID signing, notarization, final ZIP/DMG packaging, clean-Mac installation, and Gatekeeper validation remain.
- **Historical exposure:** the repeatable metadata audit confirms recipient media and private app archives remain recoverable from older repository history. The required coordinated rewrite and any necessary archive-related credential rotation have been decided and documented but not executed.
- **Google pilot:** the current OAuth approach is accepted for this pilot. Gmail scope verification and commercial compliance are intentionally deferred until the product decision to market it.

## Remaining Lifecycle

1. Connect an approved workflow through Claude Routines and prove off-Mac execution plus observable cloud run history.
2. Validate private-GitHub restore and Keychain migration against Dustin's real pilot state.
3. Validate native first-run setup on a clean Mac, then finish the remaining accessibility and error-recovery acceptance.
4. Provision the external signing/notarization credentials and prove the signed app update plus rollback on a clean Mac.
5. Run automated, clean-environment, migration, security, and guided human acceptance tests.
6. Sign with Developer ID, notarize, package, and publish a release candidate.
7. Only then give Dustin the update and validate his existing briefing, memory, skills, connectors, and accounts end to end.

## Release Gate for Dustin

Geoffrey is ready for Dustin only when all of the following are evidenced:

- a clean Mac can install and launch it without a development environment;
- Gatekeeper accepts the signed and notarized package;
- Dustin's existing state can be backed up, discovered, and used without re-creating it;
- at least two Claude conversation turns preserve context;
- multiple email accounts can be connected, distinguished, tested, and safely used;
- his existing social briefing appears in Geoffrey and runs at the promised cadence;
- a cloud-capable workflow runs while the Mac is off, or the product clearly queues it when cloud execution is impossible;
- GitHub sync succeeds, fails visibly, and can restore non-secret user state;
- credentials do not appear in GitHub, logs, migration manifests, or release archives;
- updating Geoffrey preserves state and offers a recovery path; and
- Dustin can complete the main workflow without Terminal assistance.

No release claim is based only on an implementation assertion. Every item above requires a reproducible automated check, inspected artifact, or recorded human acceptance result.

Run the enforcement check from the exact proposed release commit:

```bash
node scripts/check-dustin-release-gate.mjs
```

The check exits nonzero unless the working tree is clean, the historical-exposure audit reports `status=clean`, and every gate has a non-secret evidence reference in an owner-reviewed JSON file bound to the current commit. Copy [the evidence template](dustin-release-evidence.example.json) to `.release-evidence/dustin-gate.json`, or pass an owner-controlled path with `--evidence`. The `.release-evidence/` directory is ignored by Git so pilot account details, copied provider output, credentials, and private content are never committed. Evidence entries should contain only safe references such as artifact checksums, test-record identifiers, and review locations.

`./scripts/verify.sh` runs the same checker in report-only mode. A local verification pass remains valid development evidence, but it does not override a blocked Dustin gate.

## Change Record

| Commit | Result |
| --- | --- |
| `51aa8dc` | Added Claude capability inventory. |
| `0e703e7` | Secured release packaging and added legacy-state migration. |
| `8d6175c` | Added streaming, resumable Claude conversations. |
| `e7a644c` | Added actionable readiness and targeted capability repair. |
| `7c63c73` | Added automation discovery, classification, and bounded local queueing. |
| `0e60885` | Added safe execution and retry for approved local automations. |
| `d341ae5` | Reordered Improve Geoffrey around owner outcomes and connection readiness. |
| `bb52bab` | Added in-app automation review, drafting, and explicit approval. |
| `16af859` | Added guided Claude Routine connection and owner-reviewed run evidence. |
| `acd095d` | Added deterministic cloud result branches and validated no-merge imports. |
| `25e8eea` | Surfaced private-memory sync, conflict, and credential-blocked states. |
| `03e4307` | Restored Geoffrey's native app and in-app brand identity. |
| `01c9e9c` | Added a portable, secret-free recovery map. |
| `c9b2368` | Added verified private-memory restore into an isolated second environment. |
| `9072f3b` | Moved account credentials and refresh tokens into macOS Keychain. |
| `893abcf` | Added verified native app updates with signed metadata, package validation, release notes, and rollback. |
| `78ac9b3` | Added resumable native first-run setup. |
| `1936dec` | Added secret-free, bounded per-account connection tests. |
| `b8402fa` | Preserved last-known connections when refreshes fail or time out. |
| `abcbe23` | Exposed each setup step as a distinct accessibility element. |
| `e57a653` | Audited historical release exposure and recorded the coordinated remediation decision. |
| `0303143` | Made connection status and recovery controls independently accessible. |
| `41c8298` | Added direct failed-request retry without duplicate conversation entries. |
| `0039aa5` | Added a fail-closed, commit-bound Dustin release-gate report and evidence template. |
| `3402859` | Preserved automation inventory through failed refreshes and added explicit loading, retry, and accessible workflow actions. |
| `d8254b5` | Preserved memory status through failed checks, distinguished unchecked recovery maps, and added readable progress and retry. |
| `0778a31` | Preserved setup and capability inventory through failed checks, with explicit stale/empty/retry and accessible repair states. |

The conversation/briefing accessibility slice following `0778a31` labels Today refresh, Ask Geoffrey send, mark-handled, and repeated feedback actions. Synthetic live UI inspection also caught and corrected overlap from the new setup warning; it now occupies the detail pane above the scrollable content. Improve Geoffrey recommendation cards adapt their column count to the available width so their full action labels fit. Native build, payload, and signature checks cover these changes; live VoiceOver acceptance remains outstanding.

This record is updated with each completed slice. A branch push is not a Dustin release and does not imply that the release gate has passed.
