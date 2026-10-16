# Geoffrey Desktop Release Record

Updated: October 16, 2026

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
| macOS Keychain | Intended home for account credentials and tokens before a broader release. This migration is not complete yet. |

## Dustin Upgrade Path

Dustin should not be involved until the release candidate passes the release gate.

The planned transition is:

1. Use the existing GitHub-based update path from Dustin's terminal installation to deliver the desktop release candidate.
2. Install `Geoffrey.app` and let it place its versioned runtime in `~/Library/Application Support/Geoffrey/engine`.
3. Before changing state, create a permission-restricted local backup at `~/.geoffrey/backups/pre-desktop-v1`.
4. Discover the existing `~/Geoffrey` workspace, `~/.geoffrey/accounts.json`, current-memory pointer, private GitHub memory repository, and likely automation files.
5. Write a secret-free migration inventory to `~/.geoffrey/migration-v1.json` and continue using the existing private state in place.
6. Validate the desktop app against Dustin's real configuration. Keep the old checkout recoverable until this validation succeeds.
7. After the transition is proven, make the app's own signed update flow the supported update mechanism. The current in-app updater is not yet release-ready.

Migration is deliberately non-destructive: it inventories and preserves state rather than moving or deleting Dustin's files.

## Completed and Proven

### Release safety

- Removed 12 tracked screenshots containing real recipient information from the current branch.
- Removed the stale 98 MB private-beta app archive from the current branch.
- Changed the Mac app builder to an explicit payload allowlist.
- Added a release-safety checker that blocks credentials, token/account files, environment files, Git metadata, screenshots, recipient material, and development artifacts.
- Rebuilt the Claude distribution archives with the same safety exclusions.

These items may still exist in older Git history or tags. Before any public release, determine whether a coordinated history rewrite and credential rotation are required. Current packages pass the safety checker; historical removal has not been claimed.

### Automatic migration

- Added a legacy-state discovery and migration command.
- Added a `0600` pre-migration backup and secret-free migration manifest.
- Made the app install or refresh its embedded engine atomically in Application Support.
- Kept private memory and account data outside the app bundle so replacing the app does not erase the owner state.

### Claude runtime and capability visibility

- General requests and skill building may use Claude tools and files; prepared read-only views remain constrained.
- Ask Geoffrey uses Claude's streaming JSON output, displays partial text, records the returned Claude session ID, and resumes that session for later turns.
- The owner can stop an active Claude process, start a new conversation, and see plain-language status when Geoffrey is thinking, reading approved information, checking the web or a connected account, or preparing an approved change.
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
- Added a bounded, duplicate-safe local missed-run queue for enabled workflows with explicit approval. Queue creation does not execute Claude or touch a cloud schedule.
- Added explicit Run queued, Run now, Retry, and Open last result actions for approved local work.
- Local execution uses Claude's `plan` permission mode, refuses unapproved and cloud-routed workflows before starting Claude, and never uses a permission-bypass flag.
- Successful results and bounded run history are written to private GitHub-backed memory; failures remain in the local queue for retry and are also recorded portably.
- Common credential forms are redacted before portable results or errors are written.
- A single-run lock prevents overlapping local automations from racing queue/history writes; locks older than the bounded execution window are recoverable.
- Cloud setup routes to Claude Routines. A declared `active` state is downgraded to `needs_verification` unless the portable workflow also has a `verified_at` timestamp.
- Verified from Anthropic's current documentation that supported off-Mac execution exists through Claude Code routines and Claude Managed Agents scheduled deployments. Managed Agents scheduling is beta and requires an agent, environment, per-run initial event, POSIX cron expression, IANA timezone, credentials/vault configuration, and appropriate budgets and permissions. Geoffrey does not silently provision those resources.

Primary references: [Claude Code routines](https://code.claude.com/docs/en/routines), [Claude Managed Agents scheduled deployments](https://platform.claude.com/docs/en/managed-agents/scheduled-deployments), and [secure deployment guidance](https://platform.claude.com/docs/en/managed-agents/secure-deployment).

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
- behavioral tests: 19 passed, 0 failed;
- isolated Claude stream parser tests: pass for session identity, partial text, tool activity, final results, structured failures, and non-JSON diagnostics;
- isolated readiness tests: pass for all-ready, multi-account repair, signed-out, first-use, empty-inventory, and capability-attention states;
- isolated automation presentation tests: pass for cloud-capable, active-cloud, Mac-required, and review labels;
- Claude package safety/currentness: pass;
- Mac app build and payload safety: pass;
- isolated Mac app checks using a temporary home and fake Claude authentication: pass; and
- strict code-signature verification: pass using an ad hoc signature.

The behavioral tests cover automation discovery, secret exclusion, cloud/local/review routing, bounded missed-run queuing, approval enforcement, portable draft/approval saves, imported-candidate deduplication, atomic rejection of credential-bearing definitions, safe Routine-link validation, unverified connected state, owner-reviewed run evidence, successful local execution, failure and retry, concurrency refusal, result portability, credential redaction, capability inventory aggregation and repair classification, the multi-account MCP contract, Outlook filtering and free-text handling, recipient-label safety/no-send behavior, missing-category degradation, migration without token leakage, Claude stream parsing, and owner-facing readiness decisions. The isolated Mac check saves a draft through the public command, proves that it round-trips without becoming enabled, and proves that a Routine link remains `connected` with no verification timestamp until a reviewed run is recorded. The built Ask Geoffrey, Improve Geoffrey, and Connections interfaces were previously inspected visually in dark mode for hierarchy, legibility, clipping, and action clarity. The rebuilt Automation Center empty state and add/review sheet were inspected in the live app on October 16 for hierarchy, required fields, schedule controls, private-memory destination, and explicit approval clarity. The cloud setup sheet compiles and is covered by accessibility-copy and behavior checks; its populated visual acceptance remains part of the fixture-backed or Dustin-state pass.

## Honest Limitations and Remaining Work

The following are not complete and must not be presented as finished:

- **Cloud automation:** discovery, classification, local queueing/execution, portable local results, retry history, and the guided Routine connection/evidence flow are implemented. A real Routine still must be created in Claude, run while the Mac is off, and validated against Dustin's actual briefing. Geoffrey currently records owner-reviewed evidence because Claude's supported `/schedule` management commands are interactive and unavailable to its noninteractive app process. The cloud result remains in its Claude session; automatic import into Geoffrey private memory is not implemented yet.
- **Secrets:** existing account data is preserved, but migration to macOS Keychain and recovery/export rules remain.
- **GitHub portability:** workflow definitions, results, and bounded run history now use private memory and the existing sync path, but the complete schema for skills and connectors plus visible sync failure, conflict, and restore handling still needs implementation and testing.
- **Connections:** add/reconnect/remove and health explanations exist, but still require clean-Mac and Dustin-state acceptance testing.
- **Updates:** the legacy GitHub updater can deliver the first desktop transition, but the installed Application Support engine is not itself a Git checkout. A signed, app-native update mechanism with release notes and rollback must replace the current placeholder.
- **Distribution:** the app is ad hoc signed only. Developer ID signing, notarization, final ZIP/DMG packaging, clean-Mac installation, and Gatekeeper validation remain.
- **Historical exposure:** sensitive artifacts removed from the current branch remain recoverable from older repository history until separately remediated.
- **Google pilot:** the current OAuth approach is accepted for this pilot. Gmail scope verification and commercial compliance are intentionally deferred until the product decision to market it.

## Remaining Lifecycle

1. Connect an approved workflow through Claude Routines and prove off-Mac execution plus observable cloud run history.
2. Complete GitHub portability, Keychain secret storage, backup, restore, and recovery tests.
3. Finish first-run setup, accessibility, and error recovery.
4. Implement the signed app update path and release notes.
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

## Change Record

| Commit | Result |
| --- | --- |
| `51aa8dc` | Added Claude capability inventory. |
| `0e703e7` | Secured release packaging and added legacy-state migration. |
| `e7a644c` | Added streaming conversation readiness and targeted capability repair. |
| This slice | Added automation discovery, classification, UI, and bounded local queue creation. |
| Current slice | Added guided Claude Routine setup, least-privilege connector review, connected-vs-reviewed states, safe link validation, and portable owner-reviewed run evidence. |

This record is updated with each completed slice. A branch push is not a Dustin release and does not imply that the release gate has passed.
