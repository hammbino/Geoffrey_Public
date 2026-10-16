# Geoffrey Desktop Release Record

Updated: October 15, 2026

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
- behavioral tests: 7 passed, 0 failed;
- isolated Claude stream parser tests: pass for session identity, partial text, tool activity, final results, structured failures, and non-JSON diagnostics;
- Claude package safety/currentness: pass;
- Mac app build and payload safety: pass;
- isolated Mac app checks using a temporary home and fake Claude authentication: pass; and
- strict code-signature verification: pass using an ad hoc signature.

The behavioral tests cover capability inventory aggregation, the multi-account MCP contract, Outlook filtering and free-text handling, recipient-label safety/no-send behavior, missing-category degradation, migration without token leakage, and Claude stream parsing. The built Ask Geoffrey interface was also inspected visually in dark mode for hierarchy, legibility, clipping, and composer layout.

## Honest Limitations and Remaining Work

The following are not complete and must not be presented as finished:

- **Automation:** the cloud/local execution router, existing-automation discovery, import, scheduling view, missed-run queue, and catch-up behavior remain to be built and tested.
- **Secrets:** existing account data is preserved, but migration to macOS Keychain and recovery/export rules remain.
- **GitHub portability:** memory exists, but the complete portable schema for skills, connectors, automation manifests, results, and restore still needs implementation and failure testing.
- **Connections:** account add/test/repair/remove flows and health explanations need to be completed in the app.
- **Updates:** the legacy GitHub updater can deliver the first desktop transition, but the installed Application Support engine is not itself a Git checkout. A signed, app-native update mechanism with release notes and rollback must replace the current placeholder.
- **Distribution:** the app is ad hoc signed only. Developer ID signing, notarization, final ZIP/DMG packaging, clean-Mac installation, and Gatekeeper validation remain.
- **Historical exposure:** sensitive artifacts removed from the current branch remain recoverable from older repository history until separately remediated.
- **Google pilot:** the current OAuth approach is accepted for this pilot. Gmail scope verification and commercial compliance are intentionally deferred until the product decision to market it.

## Remaining Lifecycle

1. Finish capability readiness, recommendations, connection repair, and approval explanations around the proven conversation runtime.
2. Build the hybrid automation center, import Dustin-compatible workflow definitions, and prove cloud and queued-local paths.
3. Complete GitHub portability, Keychain secret storage, backup, restore, and recovery tests.
4. Finish connection management, first-run setup, accessibility, and error recovery.
5. Implement the signed app update path and release notes.
6. Run automated, clean-environment, migration, security, and guided human acceptance tests.
7. Sign with Developer ID, notarize, package, and publish a release candidate.
8. Only then give Dustin the update and validate his existing briefing, memory, skills, connectors, and accounts end to end.

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

This record is updated with each completed slice. A branch push is not a Dustin release and does not imply that the release gate has passed.
