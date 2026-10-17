# Current Product Status

Updated: October 17, 2026

The current effort is the native Mac release for Dustin. The terminal interface is not the future product, but its state must be preserved. The authoritative scope, evidence, limitations, and release gate are in [Desktop Release Record](DESKTOP-RELEASE.md).

## Proven Now

- Native Mac app builds as Geoffrey `0.14.0` (build 16).
- Geoffrey's revised illustrated identity is packaged in native Mac icon sizes and appears in the sidebar as “Geoffrey — Your AI chief of staff”; the original portrait asset remains preserved.
- The Memory screen can build and refresh a versioned, secret-free recovery map covering approved private-memory skills, email/calendar connection definitions, Claude MCP/plugin definitions, hashes, Git repository metadata, and explicit reconnect requirements.
- A guided Memory-screen restore clones private GitHub memory into a new owner-only folder, rejects overwrites, credentials, symbolic links, unsupported maps, changed skill hashes, and unverified checkout artifacts, then restores only the verified memory pointer. A clean second-environment test proves credentials and connected-account state are not recreated, and a failed pointer update removes the staged clone.
- Account labels and connection metadata remain in an owner-only, secret-free registry while OAuth client details and refresh tokens live in versioned macOS Keychain items. Existing plaintext registries migrate transactionally on first use; legacy backups are scrubbed only after Keychain storage succeeds, and failed migration preserves the original state for retry. The Connections screen shows the protection or reconnect state.
- Every connected email/calendar account now has an explicit bounded Test connection action. It verifies mailbox identity and calendar access without reading messages, returns only secret-free health, and gives targeted ready, reconnect, network, timeout, or removed-account recovery guidance.
- Connections shows explicit checking, empty, and refresh-failure states. A failed or timed-out refresh preserves the last known account list instead of falsely claiming that no accounts are connected, and offers a visible retry.
- Connection recovery now keeps failure copy and its retry control as separate accessibility elements, gives icon-only refresh and account-management controls explicit labels, and hides decorative status icons from assistive technology.
- Settings now uses a native signed-update flow instead of handing the owner to the legacy Git checkout. Signed manifest verification, HTTPS-only transport, bounded archive size, exact SHA-256 and byte-count checks, unsafe-path and symlink rejection, same-bundle and same-Developer-ID-team validation, release notes, daily quiet checks, private staging, a second helper-side signature check, failure relaunch, and one-version rollback are implemented. Ad-hoc builds refuse installation, and the production release builder requires Developer ID signing plus Apple notarization.
- The 0.14.0 Settings update state was visually inspected in the built dark-mode app; version, action, safety explanation, and the honest ad-hoc-build status were legible and unclipped.
- The app installs its versioned engine in `~/Library/Application Support/Geoffrey/engine`.
- Incomplete first-run setup now opens a native, resumable guide for the Geoffrey helper, Claude sign-in, one email/calendar account, private GitHub backup, and private memory. Completed steps remain saved, dismissal returns to a visible Continue setup action, and create/restore flows stay inside Geoffrey.
- Each first-run step is exposed as a separate macOS accessibility element with an explicit complete, next-step, or not-complete state and its recovery detail.
- Legacy setup discovery covers the Geoffrey workspace, account registry, current-memory pointer, private GitHub memory, and likely automation files.
- Migration creates a permission-restricted local backup and a secret-free inventory without deleting or relocating the old state.
- Ask Geoffrey streams Claude responses, records and resumes Claude session IDs, and preserves the visible conversation locally with `0600` permissions. If request preparation, launch, or execution fails, the alert offers a direct retry without duplicating the owner's chat message.
- Synthetic live UI inspection proves the setup-warning layout, Memory conflict/unchecked/retry/scroll state, automation-refresh failure/retry state, and stale capability/disabled-repair state. These fixtures do not establish real-account or VoiceOver acceptance.
- Today refresh, Ask Geoffrey send, and briefing mark-handled controls have explicit accessible names. Repeated priority and section feedback actions identify the affected content, and decorative readiness icons are hidden from assistive technology.
- Owners can stop an active request and see understandable thinking, connected-account, web, reading, and approved-change states.
- Claude sign-in status and login flow are surfaced through the app.
- Capability inventory combines Claude skills, plugins, and MCP servers.
- Improve Geoffrey preserves setup and capabilities when checks fail or time out, offers separate retry controls, and distinguishes successful empty inventory from loading or failure. Failed/partial setup checks never automatically reopen first-run setup; readiness warns about stale results and disables repair from unverified inventory.
- Improve Geoffrey summarizes Claude, email/calendar, private memory, GitHub, and capability readiness before recommending anything new.
- Missing setup and unhealthy capabilities route to targeted actions, including account repair, Claude or GitHub sign-in, disabled-plugin enablement, and MCP reconnection guidance.
- Improve Geoffrey places the outcome-first “Connect a business tool” action above the longer inventory of available capabilities.
- Release packages use an explicit allowlist and pass sensitive-material checks.
- A metadata-only Git history audit now reports risky historical object counts without printing recipient filenames or contents. It confirms 12 recipient-media blobs and two private app-archive blobs remain reachable, so a coordinated rewrite is required before broader distribution; credential-named historical files were not found.
- A fail-closed Dustin release-gate checker now requires a clean exact commit, clean history audit, and owner-reviewed evidence for every acceptance criterion. Its evidence file is kept outside Git; the current report is `blocked` and cannot be converted into readiness by a passing local build alone.
- A live authenticated two-turn Claude session successfully resumed the same session and recalled information from the first turn.
- Geoffrey's exact `stream-json` flags were verified against the installed Claude Code `2.1.301` event format.
- The Mac conversation interface has been visually inspected in the built app.
- Automation refresh now preserves the last known workflows and counts on command failure, malformed or unsupported inventory, and timeout. Loading and failed-refresh states do not claim no workflows exist; a separate retry action is available, and card actions identify the workflow for assistive technology.
- The Automation Center discovers portable workflow manifests plus likely terminal-era briefing/routine files without changing a schedule.
- Workflows are classified as Claude-cloud capable, Mac-required, or needing review based on declared dependencies and connection readiness.
- Imported workflows remain disabled until explicitly approved, and the interface distinguishes “cloud capable” from an actually active Claude cloud deployment.
- Approved local workflows can accumulate a bounded, duplicate-safe queue of missed daily occurrences when Geoffrey next opens; queue creation never runs the workflow.
- The portable automation manifest lives in private GitHub-backed memory, while local queue state remains outside GitHub.
- Owners can add a workflow or open an imported workflow in an in-app review sheet, edit its plain-language purpose and task, choose Claude cloud or this Mac, choose one to three daily times, and save either a disabled draft or an explicitly approved definition.
- Saving uses an atomic, owner-only portable manifest update, rejects common credential formats without overwriting the prior definition, deduplicates imported candidates by their source path, and attempts the existing private-memory GitHub sync.
- Approving a cloud-capable definition does not create or claim a live Claude schedule; its deployment remains `not_connected` until a separate supported cloud setup is verified.
- Approved cloud-capable workflows now open a guided Geoffrey setup sheet with a copyable Claude Routine brief, least-privilege connector review, cadence confirmation, and clean Claude link validation.
- Geoffrey records a Routine as `connected` without calling it active. It only shows “Cloud run reviewed” after the owner uses Run now in Claude, opens the resulting session, confirms the actual result, and records that session link.
- Routine and run links plus owner-review timestamps can sync in private memory; API trigger tokens and other credentials are rejected from this portable path.
- The guided Routine brief now includes a deterministic, workflow-specific `claude/` result branch and a strict JSON envelope contract.
- A connected cloud workflow exposes Check results in Geoffrey. The importer fetches only that exact remote branch, never checks it out or merges it, validates bounded envelopes, rejects malformed or mismatched files, redacts common credential forms, deduplicates prior imports, and writes accepted briefings plus run history into normal private GitHub-backed memory.
- Failed memory-status reads preserve the prior backup and recovery-map state with an explicit stale-status warning and separate Check memory status again action. An unchecked recovery map no longer claims it needs an update or displays zero counts as checked facts. Backup and map updates show text progress and are serialized with status refresh; the Memory page scrolls to keep longer recovery guidance reachable.
- The Memory screen now shows whether private memory is backed up, has local changes waiting, is only local, is conflicted, is blocked for credential safety, or otherwise needs attention, with a visible Sync now action and a plain-language recovery step.
- Private-memory sync produces a permission-restricted machine-readable status record, fast-forwards remote-only changes, rebases independent changes, pushes local versions, and aborts a real same-file conflict while proving the original local branch and file remain intact.
- Sync refuses common token, key, password, credential-file, symlink, and uninspectably large-file risks before commit or push; the local file remains untouched and the app explains why it stayed off GitHub.
- The owner can run queued work or request a run now from the Automation Center. Local automation uses Claude's read-only plan mode and refuses unapproved or cloud-routed workflows before Claude starts.
- Successful local runs produce an owner-ready result plus bounded run history in private GitHub-backed memory. Failed runs remain visible and retryable.
- A local execution lock prevents overlapping runs from corrupting queue or history state, and stale locks can recover after the bounded runner timeout.
- Common credential formats are redacted from portable automation results and errors before they can be synchronized.
- Cloud-capable cards open Claude's supported Routines surface, but Geoffrey only labels a cloud workflow active when the portable record includes a verification timestamp.
- The rebuilt Automation Center and its add/review sheet were visually inspected in the live Mac app for hierarchy, legibility, required fields, schedule controls, private-memory destination, and explicit approval clarity.

## In Progress

- Completing a real Claude Routine setup and reviewed test run against a pilot workflow.
- Clean-pilot validation of the guided restore against a real private GitHub repository.
- Dustin-state acceptance of the Keychain migration and connection repair flow.
- Dustin-state acceptance of per-account tests across his real Gmail and Outlook accounts.
- Developer ID and notarized end-to-end update/rollback acceptance on a clean Mac; the updater and release tooling are implemented, but production signing credentials have not been exercised.
- Clean-Mac and pilot-account acceptance of the complete native first-run sequence; its state model, resume behavior, build, and dark-mode layout are locally proven.
- Coordinated history rewrite, archive-related credential review/rotation, remote ref cleanup, and fresh-clone verification described in [Git History Remediation Decision](HISTORY-REMEDIATION.md).

## Not Yet Proven

- Import and execution of Dustin's three-times-daily social briefing.
- Actual cloud execution while Dustin's Mac is off.
- End-to-end publication and import from a real Claude Routine using Dustin's actual briefing; the transport and importer are implemented and synthetically proven, but real cloud execution is not yet proven.
- Automatic background polling for cloud results; the pilot currently uses the visible Check results action.
- Real private-GitHub restore acceptance on a clean pilot Mac; isolated second-environment restore is automated and passing.
- Migration of Dustin's real account credentials into Keychain; isolated adapter tests and a reversible native Keychain create/update/read/delete proof pass without exposing a credential in process arguments.
- Clean-Mac installation, Developer ID signing, notarization, Gatekeeper acceptance, and rollback.
- Publication and installation of a real signed `update.json` plus notarized Geoffrey ZIP; current signature, tamper, version, HTTPS, digest, helper packaging, and rollback-path checks are synthetic or ad-hoc-build evidence.
- End-to-end migration against Dustin's actual machine.

## Readiness

This branch is a development milestone, not a Dustin release candidate. Dustin should not be involved until the release gate in the Desktop Release Record passes.
