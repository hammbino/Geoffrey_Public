# Geoffrey Desktop Release Record

Updated: October 19, 2026

This is the authoritative record for the Mac desktop release being prepared for Dustin. It defines the intended product, what is already proven, what remains unproven, and the gate Geoffrey must pass before Dustin is asked to update.

The current manual-install test is build **28**, published at the existing `v0.14.0-desktop-test.9` download URL. It contains the section-header feedback panels, Start here action button, and read-only chat email fix from source `4e4d0ad9cdb919e514fc1ce5485991704aa1f174`. The full local suite passes with 82 engine tests; the extracted package passes signature, safety, and bundled-runtime setup checks. Exact download provenance is in [the download record](desktop-test-download.md). This updates the existing test package; it does not establish the production Dustin gate below.

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

The current tree and packages pass the safety checker. The approved October 17 cleanup stripped 18 risky blob objects—including contaminated nested bundles—from both distributed branches and removed the old beta release/download/tag. Candidate, fresh-GitHub-clone, and current-checkout audits report `status=clean`. GitHub still serves sampled old commits by ID, so applicable server-side cached-object cleanup and Dustin’s eventual source-checkout transition remain pending. The archived Google configuration is an installed-app public-client configuration; it was left unchanged at the owner’s request. See [Git History Remediation Record](HISTORY-REMEDIATION.md).

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
- signing-identity preflight tests: pass for exact public names/fingerprints, absent identities, ad-hoc identities, wrong certificate types, malformed/revoked rows, unmatched selections, and secret-free CLI output; a real missing-identity release-builder attempt left the existing app and release-output state unchanged;
- isolated owner-evidence packaging checks: pass for root/nested evidence exclusion, bundle freshness with local evidence present, rejection of evidence injected into both ZIPs, and native payload rejection outside the engine;
- Claude package safety/currentness: pass;
- Mac app build and payload safety: pass;
- isolated Mac app checks using a temporary home and fake Claude authentication: pass; and
- strict code-signature verification: pass using an ad hoc signature.
- historical archive tests: pass for safe packages, nested credentials/media, private archives, downloaded OAuth-config names, corrupt/over-budget/deep ZIP refusal, removed-from-tip history, and clean/direct/nested/incomplete shell-gate behavior;
- history exposure report: `status=clean` in the rewritten candidate, a fresh GitHub clone, and the adopted working checkout; all direct and nested risk counts are zero, with no uninspected ZIPs. GitHub cached old objects remain a separate pending cleanup.
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
- **Distribution:** a clean [test ZIP](desktop-test-download.md) is publicly downloadable as build 28 at `v0.14.0-desktop-test.9`, with its unauthenticated download and SHA-256 verified. It is an Apple Silicon-only, ad-hoc-signed, unnotarized prerelease, is not marked latest, and includes no signed update feed. The owner’s browser-downloaded copy failed first launch with an “Apple could not verify” Gatekeeper dialog; local assessment also rejects the ad-hoc build. The owner later manually approved launch and reached the account form; live account acceptance remains pending, and manual approval does not establish normal Gatekeeper acceptance. The checked Mac has zero valid signing identities and the owner’s developer account shows an enrollment prompt. An early signing-identity preflight now rejects unusable publisher identities before rebuilding/creating output. Developer Program enrollment/team access, Developer ID signing, notarization, final release packaging, clean-Mac installation, and Gatekeeper validation remain.
- **Historical cleanup:** the owner approved cleanup after confirming there is one developer and Dustin is the only other installation. Eighteen risky blobs were stripped from distributed history, the contaminated beta release/download/tag were removed, and both branches were published with exact ref leases. Candidate and fresh-GitHub-clone audits report `status=clean`; retained branch-tip source files are identical to the originals, and this checkout now uses fresh clean Git metadata. GitHub still serves sampled old commits by ID, so server-side cached-object cleanup remains pending. Dustin’s old checkout also needs a guided transition before its next Git update. The archived Google credential was confirmed to be an installed-app public-client configuration; the owner deferred rotation, and no account compromise is asserted.
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

The check exits nonzero unless the working tree is clean, the historical-exposure audit reports `status=clean`, and every gate has a non-secret evidence reference in an owner-reviewed JSON file bound to the current commit. Copy [the evidence template](dustin-release-evidence.example.json) to `.release-evidence/dustin-gate.json`, or pass an owner-controlled path with `--evidence`. The `.release-evidence/` directory is ignored by Git and excluded from repository ZIP staging at any depth. Package checks reject that path in either repository bundle or anywhere inside the native app. Keep pilot account details, copied provider output, credentials, and private content out of committed files. Evidence entries should contain only safe references such as artifact checksums, test-record identifiers, and review locations.

`./scripts/verify.sh` runs the same checker in report-only mode. A local verification pass remains valid development evidence, but it does not override a blocked Dustin gate.

## Change Record

| Commit | Result |
| --- | --- |
| `70005aa` | Added Claude capability inventory. |
| `3a417c8` | Secured release packaging and added legacy-state migration. |
| `9f2ce37` | Added streaming, resumable Claude conversations. |
| `c4b8ecb` | Added actionable readiness and targeted capability repair. |
| `bf4f15d` | Added automation discovery, classification, and bounded local queueing. |
| `9c59039` | Added safe execution and retry for approved local automations. |
| `f456fd7` | Reordered Improve Geoffrey around owner outcomes and connection readiness. |
| `f2ea3d7` | Added in-app automation review, drafting, and explicit approval. |
| `16c50ea` | Added guided Claude Routine connection and owner-reviewed run evidence. |
| `c05f673` | Added deterministic cloud result branches and validated no-merge imports. |
| `22ca308` | Surfaced private-memory sync, conflict, and credential-blocked states. |
| `b69ee71` | Restored Geoffrey's native app and in-app brand identity. |
| `ee2845b` | Added a portable, secret-free recovery map. |
| `57ba214` | Added verified private-memory restore into an isolated second environment. |
| `64fd49b` | Moved account credentials and refresh tokens into macOS Keychain. |
| `cdf7cda` | Added verified native app updates with signed metadata, package validation, release notes, and rollback. |
| `15fa092` | Added resumable native first-run setup. |
| `bb8ab3c` | Added secret-free, bounded per-account connection tests. |
| `28c0e09` | Preserved last-known connections when refreshes fail or time out. |
| `4aa43e3` | Exposed each setup step as a distinct accessibility element. |
| `83f170d` | Audited historical release exposure and recorded the coordinated remediation decision. |
| `79872a2` | Made connection status and recovery controls independently accessible. |
| `9ee1c67` | Added direct failed-request retry without duplicate conversation entries. |
| `5fd744b` | Added a fail-closed, commit-bound Dustin release-gate report and evidence template. |
| `fa76b28` | Preserved automation inventory through failed refreshes and added explicit loading, retry, and accessible workflow actions. |
| `f4d88f6` | Preserved memory status through failed checks, distinguished unchecked recovery maps, and added readable progress and retry. |
| `19afd9f` | Preserved setup and capability inventory through failed checks, with explicit stale/empty/retry and accessible repair states. |
| `07b4131` | Labeled core conversation/briefing controls, inspected synthetic recovery layouts, fixed setup-warning overlap, and adapted recommendation cards to fit full action labels. |
| `d8cb39a` | Excluded owner evidence from repository ZIPs and rejected evidence paths in bundle/native-payload checks. |
| `a81f05b` | Added bounded nested-ZIP auditing and regression tests and prepared private recovery/inventory material. |
| `18bf94f` | Recorded verified two-branch history cleanup, beta removal, fresh-clone adoption, and pending server purge/source transition. |
| `48f068e` | Published and verified the public first-install test download and recorded its unnotarized development boundary. |

The signing-preflight slice following `48f068e` records the owner’s Gatekeeper-blocked first launch and adds an early secret-free identity check to production release builds. A missing Developer ID Application identity blocks before app/output mutation. Enrollment/team access, notarization, real downloaded launch acceptance, and Dustin release evidence remain outstanding. Earlier Change Record hashes above were translated through git-filter-repo’s commit map. GitHub cached-object cleanup and Dustin’s source-checkout transition remain pending.

This record is updated with each completed slice. A branch push is not a Dustin release and does not imply that the release gate has passed.

The account-connection simplification following `e82e6b2` replaces the provider picker, required account label, purpose field, and separate Continue action with two direct provider sign-in buttons. The provider-verified email identifies a new account. Repeated connections retain an existing alias and purpose, automatic ids cannot collide with other accounts, and reconnect refuses a different signed-in mailbox before writing credentials. The manual CLI label path remains supported. The owner reached the old account form after manually approving the development download; that screenshot establishes progress to setup, not successful account connection or normal Gatekeeper acceptance. The published test.1 asset is unchanged and does not yet include this UI improvement.

The simplified-flow app advances to build 17 so opening it refreshes the installed engine instead of reusing build 16, which does not support automatic account labels. Local verification passes; the Dustin gate remains blocked.

The private-memory completion fix following `ba3445e` saves the owner-only current-memory pointer after the local Git repository is initialized, before GitHub authentication/repository creation/push. The original order could leave a populated `~/Geoffrey` folder unselected after remote failure, so setup continued to ask for creation and retries hit the nonempty-folder safeguard. Existing-folder overwrite refusal remains intact. Explicit `--business Personal` no longer triggers a terminal question from the native app. Creation now rechecks local memory even on remote failure, reports local readiness separately from backup failure, and queues a follow-up refresh when an older status check is already active. Integration tests run the real creation command in disposable homes with a fake GitHub publisher, proving the private pointer is present at the remote-operation boundary on both success and failure. Build 18 refreshes the installed engine. Real owner setup/backup acceptance and the Dustin gate remain pending.

Following the owner’s request to download the update through the same browser route planned for Dustin, build 18 from `6f253116d20db633bdc14253a1f8529c57e3d27a` is published as `v0.14.0-desktop-test.2`. Draft target, prerelease state, asset sizes and SHA-256 digests were verified before publication; the published ZIP was fetched without authentication and matched the tested bytes. The [download record](desktop-test-download.md) contains installation steps and checksum. Earlier statements about the public asset lacking these fixes describe test.1; test.2 includes both fixes. No latest-production flag or signed update feed was published, and manual approval does not satisfy the Gatekeeper or Dustin gates.

The Claude sign-in feedback correction following `569e78d` removes the generic “needs a little attention” modal from successful login. Success updates Claude readiness and refreshes setup; only unsuccessful login displays the existing recovery alert. The owner screenshot showed the older contradictory success/attention dialog. Build 19 contains the correction; live owner acceptance and the Dustin gate remain pending.

Build 19 from `65dc92a46dd3246786d7facc7b798a959f6a5217` is published as `v0.14.0-desktop-test.3`. Native and package checks, ZIP round-trip signature/payload checks, draft target/digest inspection, and an unauthenticated public download comparison pass. It retains the preceding setup fixes and adds the Claude-success alert correction. This remains an unnotarized prerelease with no production update feed or Dustin readiness claim.

The connection-removal correction following `216c843` addresses the owner-reported failure on a malformed Keychain entry. A read-only diagnostic reported invalid JSON and a 128-byte stored value without displaying credentials. A uniquely named dummy reproduced incomplete storage through the old security-tool password prompt. The new native writer uses SecItemUpdate/SecItemAdd with bounded stdin data, permits only Geoffrey’s service, and configures access for the helper and Apple’s fixed security tool. Existing system read/delete lookup remains scoped to service and account. Exact read-back is required before registry migration or connection success. Raw prior values support removal and reconnect rollback even when JSON is damaged. Missing writer binaries fail closed rather than reuse the truncating write path; source checkouts can use the helper from their local app build.

Initial diagnostic attempts could prompt for Keychain access; the owner was told to deny the diagnostic prompt. Those checks were replaced with a reversible native proof using `--no-ui`, which disables Keychain interaction and fails rather than asks for a password. The proof creates, updates, fully reads, and deletes long dummy values; fixture cleanup passes. It is deliberately separate from the default isolated verification suite because it uses the login Keychain. No real account credential was altered by these diagnostics. Build 20 includes the helper and targeted removal recovery copy. The published test.3 asset still has the old writer; refreshed download and real account acceptance remain pending.

Build 20 from `cf98361a86072494b94fcbae5171355045a7447a` is published as `v0.14.0-desktop-test.4`. Full local verification passes with 56 connector tests. The final signed app’s exact helper passes a no-UI, long-value dummy create/update/read/delete test with cleanup. ZIP-round-trip payload and signature checks, draft commit/digest inspection, and an unauthenticated public-download byte comparison pass. The [download record](desktop-test-download.md) supersedes test.3 for owner testing. Real account removal/reconnect acceptance remains pending; the Dustin gate stays blocked.

Build 20 failed real reconnect acceptance: the owner entered the requested Keychain password yet account status still requested reconnect. The subsequent no-UI native read returned authorization failure, not a usable credential. The earlier writer-only proof did not establish interoperability with the separate security-tool reader; real reconnect remained unproven. Build 21 removes that split path. All normal Keychain operations use the native helper with interaction explicitly disabled. Reconnect creates and verifies a new credential slot before atomically switching the non-secret registry pointer, so it never reads or overwrites an inaccessible old item. Old-item cleanup is attempted without UI; if access is denied, that obsolete item remains in Keychain but is no longer selected or used by Geoffrey. A failed registry switch discards the staged slot and preserves the original pointer/item. Existing credentials are not automatically recovered or silently deleted.

Two regression tests cover an inaccessible old item (no read attempted, replacement usable even when old cleanup fails) and failed registry-switch rollback. The explicit `scripts/test-native-account-reconnect.py` proof uses an isolated registry, uniquely named dummy Keychain items, the real store/native adapter, mocked HTTP responses, and a fresh account-status process. It verifies damaged credential → reconnect → full long-value read → mail/calendar ready → remove, with no-UI enforced and dummy cleanup. It is optional because it uses the login Keychain, and it does not contact Google or validate real account consent. Unrelated uncommitted sidebar/readiness edits are excluded from the release build. The refreshed artifact and owner acceptance remain pending; Dustin readiness stays blocked.

Build 21 from `e57c29cb2caeab2a2a7e10482dbab844045dede3` was published as owner-test prerelease `v0.14.0-desktop-test.5`. Build 22 from `bf45adc9e687480df77bb202ccbd2cc1244457dd` is published as `v0.14.0-desktop-test.6`, adding the shorter local-first setup path, optional retryable GitHub backup, multi-account follow-up, and bundled runtimes requiring macOS 15+. Full local verification passed 64 connector tests, native/model/package checks, and strict ad-hoc signature verification. ZIP extraction preserved the signature, and the unauthenticated public download matched the tested 183,290,267-byte ZIP with SHA-256 `736677208e3402a94c342b4fd6df93c4029f5d313185a5de19ba34af9176f7d8`. The [download record](desktop-test-download.md) has the install steps. Test.6 remains unnotarized, is not marked latest, has no production update feed, and does not satisfy the Dustin gate.

Build 23 from `33e33d2e1e26a6c1c574c9138b9201bfefaf2fc0` is published as owner-test prerelease `v0.14.0-desktop-test.7`. Account icons now use one neutral color instead of provider-specific red and blue; provider names and addresses remain visible. Full local verification passed again, ZIP extraction preserved the strict ad-hoc signature, and the unauthenticated public download matched the tested 183,291,365-byte ZIP with SHA-256 `060e3b9e7993473ff775df2170cbbcbd90af6dbebdd63ee491cad0c5946ec5a2`. It is not marked latest and does not satisfy the notarization, clean-Mac, or Dustin release gates.

Build 24 from `f179db81f39c131ef99cf7a39228ad90dc42a32a` is published as owner-test prerelease `v0.14.0-desktop-test.8`. Backup setup now distinguishes GitHub's blank default-branch object from actual Git refs, and the app bundles Git's macOS Keychain credential helper. Regression tests accept a truly empty private repository and reject existing refs even when the API reports a blank branch. Full local verification passed 66 connector tests; the packaged Git authenticated to the owner's empty private repository in a read-only check without uploading memory. ZIP extraction preserved the strict ad-hoc signature, and the unauthenticated public download matched the tested 184,287,172-byte ZIP with SHA-256 `0a5d598df55b69ebb1ca732a7b5161ef6534997645c60e437076c294e2066b8e`. The separate live email/calendar read failure remains under investigation. Test.8 is not marked latest and does not satisfy notarization, clean-Mac, or Dustin release gates.

Build 26 adds optional contextual feedback to briefing and operational-result items (Good, Bad, More like this, and an optional note), retaining saved selections and preserving input on failure. The calendar context now uses the current macOS local day instead of a rolling 24-hour interval, preserves event dates and end times, excludes next-day/cancelled/declined instances, and avoids inferring availability from failed or truncated reads. Local automated verification covers these corrections, and an installed-app briefing was regenerated with the correct local date and schedule. These local results do not establish clean-Mac installation, recipient migration, cloud cadence, or signed-update acceptance.

Release preparation also corrects production update metadata to read the minimum macOS version from the completed app, including the bundled runtimes' requirement. The Developer ID preflight still reports no valid identity on the checked Mac. Build 26 may be packaged for owner testing while signing, notarization, clean-Mac acceptance, and the existing Dustin gate remain outstanding. Dustin has not been contacted.

Build 26 from `d0a433b2a68f99e8b7b55acb06916c277a075ff4` is published as owner-test prerelease `v0.14.0-desktop-test.9` after explicit owner approval to publish its source and verified package. Full local verification passed with 79 connector tests, native app/model checks, package safety, historical-exposure audit, and refreshed distribution archives. ZIP extraction retained the strict ad-hoc signature and exact tested helper bytes. Fresh setup using only bundled runtimes and macOS utilities passed; an isolated repeat-upgrade fixture preserved two account definitions, memory, a custom skill, a briefing definition, and recoverable backups, and packaged feedback saved/reopened. The unauthenticated public download matched the tested 184,334,789-byte ZIP with SHA-256 `255b04d768c2ee0b4f3afb91f53e7ebead6552c66e2131de40b906bf44541251`. The release is not marked latest and has no production update feed. Apple enrollment remains deferred by the owner; notarization, normal Gatekeeper acceptance, clean-Mac UI acceptance, live recipient migration, and signed update/rollback acceptance remain pending. The [download record](desktop-test-download.md) supersedes test.8 for owner testing.
