# Current Product Status

Updated: October 19, 2026

The current effort is the native Mac release for Dustin. The terminal interface is not the future product, but its state must be preserved. The authoritative scope, evidence, limitations, and release gate are in [Desktop Release Record](DESKTOP-RELEASE.md).

## Connected tools, GitHub sync, and cloud delivery — build 30

Build 30 routes GitHub operations through the app's existing GitHub CLI sign-in with per-process credential settings, preventing inherited osxkeychain helpers from presenting password dialogs. Sync, backup setup, restore, and cloud-result import share that path; no global Git settings or tokens are written. Memory shows current progress while syncing and refreshes stale local-only status after a remote is connected. The installed app completed a real private-memory backup without a Keychain prompt.

Available capabilities now have Run/Use actions, a task field, and a handoff to Ask Geoffrey. Selected skill instructions are loaded into the request directly instead of requiring Claude to read outside its working directory. Internal paths and skill instructions stay out of the displayed task message. Chat rendering avoids the macOS text-selection layout loop encountered during live verification and opens at the latest messages.

Every chat/action request receives the current secret-free Geoffrey account registry. Normal chat uses strict MCP configuration so separate Claude Gmail connections cannot replace Geoffrey's multi-account reader. The live registry and native readiness check show five healthy accounts: four Google and one Microsoft. A live capability request also correctly recognized all five; the completed Run-button test used its supplied skill instructions, and a fresh chat list_accounts call independently enumerated all five. All 92 engine tests and the complete local verification suite pass. Regression tests cover five-account enumeration, exact selected-capability instructions, missing-skill refusal, strict chat routing, credential-helper isolation, and stale backup status.

Both owner-approved Social Media cloud tasks are enabled daily at 08:00 and 14:30 America/Denver with no extra connectors. Both manual delivery tests succeeded; two validated envelopes imported into local history without checking out or merging the cloud result branch. The first test preceded the memory upload; the afternoon test read the backed-up memory. The private repository's default branch was corrected to main, and both schedule links plus the reviewed run are recorded. Build 30 replaces build 28 at the existing test.9 download URL; exact provenance and checksum are in the download record.

## Recurring-work repair — local build 29

Build 29 distinguishes saved cloud definitions from connected schedules, preserves recorded cloud links when editing, and marks changed provider settings as pending. Review sheets reset to the selected workflow. Delete removes the definition and suppresses rediscovery while preserving original source files, feedback, and run history; connected cloud schedules must first be stopped in Claude. Migration no longer mistakes briefing reactions and generated result files for recurring workflows. Claude's current scheduled-task links and multiple daily task links are supported, including result import from either linked task.

All 89 engine tests and the complete native app checks passed for build 29. Its live Automations view showed the correct single workflow, an explicit disconnected state, and Delete. The saved Social Media review opened with its task, approved cloud route, and both times intact. The owner subsequently approved cloud setup and delivery testing, completed in build 30 above. Build 29 did not replace the build 28 public download.

## Chat email access — build 28

Build 28 gives chat fresh connected-account context and an explicit local request date. Email and calendar searches use a per-request `geoffrey_readonly` MCP server backed by the packaged engine and existing Geoffrey Connections. Only six explicit read tools are allowlisted. The server does not register label changes or draft creation in this mode, and no persistent Claude permission settings are changed. Tool permission denials are retained from Claude's result and produce a retryable app error rather than publishing a historical fallback as a successful answer. Failed snapshots are explicitly unverified; old briefings cannot establish pending replies or current meetings. Normal action permission mode is selected by omitting the optional CLI mode flag, matching the bundled CLI.

The native build, complete Mac app checks, and all 82 engine tests pass. Tests cover fresh chat context, current date, the read-only tool registry, failure handling, and permission denial despite a nominally successful Claude result. The corrected app is installed and relaunched locally. After explicit owner approval, a live read-only test through the installed packaged Claude runner in planning mode successfully listed accounts, searched one Google mailbox for one recent message, and read that message using `geoffrey_readonly`. All three calls succeeded, the result was `READ_OK`, and permission denials were empty. No mailbox changes were made and no message content was included in the verification output. Build 28 was published at the existing `v0.14.0-desktop-test.9` URL and is superseded by build 30; see [the download record](desktop-test-download.md) for its exact source and checksum.

## Local interaction improvements — build 27

Local build 27 moves Feedback to section headers, with separate item reactions and notes inside each section's popover. Start here now has a Do this button that submits the selected action and dated briefing context, opens Ask Geoffrey, and displays progress and results there. Each selected task starts a fresh Claude session with normal tool permission checks; follow-up answers resume that task, and New conversation resets to planning mode. Future briefings describe a concrete task and use the button instead of asking the owner to reply yes. The build number refreshes the installed engine so the new action prompt is included.

The native build, app checks, and isolated UI handoff pass. Fixture tests cover exact action/context routing, duplicate clicks, results, follow-ups, failures, retry, and session reset. These checks do not establish a live mailbox mutation. Build 27 was local only; its changes are included in the build 28 test download.

## Feedback and briefing corrections — build 26

Build 26 was originally published as owner-test prerelease `v0.14.0-desktop-test.9`, including the feedback and calendar corrections below. Its unauthenticated public download matches the verified ZIP. The production signing preflight still reports zero valid Developer ID Application identities; no clean-Mac or signed-update acceptance is claimed. The release builder now takes the update manifest's minimum macOS version from the finished app bundle so it follows the bundled runtime requirement.

Local build 26 corrects the daily calendar window to the owner's local midnight-to-midnight interval and supplies an explicit date, time zone, event dates, and end times. Next-day, cancelled, and declined instances are excluded from today's verified facts. Outlook UTC values retain their offsets. A failed account no longer discards healthy calendars, and unverified calendars or truncated coverage cannot be presented as free time. Regression cases cover next-day recurring meetings, local midnight, all-day/overnight events, daylight saving, failed reads, and provider metadata. The native command environment passes macOS's time zone to the packaged runtime.

Local build 25 replaces the repeated briefing rating controls with a small optional Feedback popover on each priority, schedule item, follow-up, open loop, waiting item, focus block, and operational result. Good, Bad, and More like this remain distinct; an optional note can be saved without a rating. Reopening loads the saved feedback, clearing removes it, and write failures retain the note and offer retry. Contextual reactions are stored atomically in private memory and supplied to future requests; local-save confirmation does not wait for optional GitHub backup. Build 26 included this feedback flow; build 28 replaces the individual buttons with section-header panels.

The setup review led to a smaller first-use path: Claude sign-in, one or more healthy email/calendar accounts, and local private memory. Multiple Google and Microsoft accounts remain supported without an app-imposed limit, including an Add another account action immediately after sign-in. GitHub backup is optional and has an explicit, retryable setup action in Memory. Build 23 gives all account icons the same neutral color; provider names and email addresses identify them.

Build 22 packages Node, Claude, Git, GitHub CLI, and their native dependencies instead of depending on tools installed on the owner's Mac. This local runtime set requires macOS 15+, recorded in the built app's minimum OS metadata. Release builders can supply explicit runtime binary paths through `GEOFFREY_RUNTIME_NODE`, `GEOFFREY_RUNTIME_CLAUDE`, `GEOFFREY_RUNTIME_GIT`, and `GEOFFREY_RUNTIME_GH`; runtime dependencies and minimum OS are checked during packaging. Build 24 also bundles Git's macOS Keychain credential helper.

Build 24 corrects private backup setup for GitHub's empty default-branch object. It verifies actual Git refs before linking a repository, so an empty private repository can be used while existing history remains protected. The packaged Git authenticated to the owner's empty private repository in a read-only check; no memory was pushed during verification. The live email/calendar read failure reported separately is not addressed by this fix.

The shared command runner now captures stdout and stderr without pipe deadlocks and bounds cancellation/timeout escalation. Account connection uses the same runner. Setup/account results publish before optional capability, automation, and recovery checks; successful migration runs once per launch. Optional backup results from an older refresh cannot replace a newer memory operation.

New executable checks cover the production command runner, production app-model transitions, failed backup creation through a real local Git push, literal names containing punctuation, missing runtime detection, and the packaged engine creating/reopening local memory with a system-only PATH. These checks do not establish live OAuth, normal Gatekeeper acceptance, or a full UI journey on a clean macOS VM. The existing release gate remains in force.

## Proven Now

- Build 20 owner acceptance failed: after reconnect and local Keychain approval, the account still reported credential repair. A no-dialog read returned a Keychain authorization failure. Build 21 uses the native helper for reads, writes, and deletes with interaction disabled. Reconnect stages a fresh uniquely keyed credential, verifies its full value, and atomically switches registry metadata without reading the inaccessible old item. Failed registry switches preserve the original connection. A native dummy-store proof now exercises damaged entry → reconnect → fresh-process account status → remove with mocked provider responses and no password dialogs. It reports email/calendar ready and cleans up all dummy items. This does not establish real Google acceptance.

- The owner’s removal failure was traced without exposing credential values to an invalid 128-byte Keychain entry. A dummy-item proof reproduced truncation through the previous interactive password transport. Build 20 uses a bundled native Security-framework writer with stdin-only full-length values and verifies exact read-back before treating a write as successful. Removal and reconnect preserve raw prior values for rollback instead of requiring valid JSON. Regression tests cover malformed-entry removal/repair, long credentials, truncated-write refusal, and failed-registry rollback. Reversible native dummy checks prohibit Keychain UI and clean up their fixture; real account reconnect/removal acceptance remains pending.

- Successful Claude sign-in now marks Claude ready and refreshes setup without displaying the generic attention alert. Failed sign-in still shows recovery guidance. The owner’s screenshot confirms successful sign-in in the earlier build; live acceptance of the quieter transition remains pending.

- Private-memory creation now selects the local `~/Geoffrey` folder before attempting GitHub backup. A failed backup leaves usable memory selected rather than restarting setup; the app checks local readiness even after a creation error and explains backup recovery separately. Setup completion requests a follow-up refresh if an older status check is still running. Isolated success/failure tests exercise the real creation command and verify the owner-only pointer exists before the remote operation. Live owner acceptance remains pending.

- Account connection now starts with **Continue with Google** or **Continue with Microsoft**, which opens provider sign-in immediately. New accounts use the provider-verified email address without requiring a label or purpose. Existing aliases and purposes survive reconnect, and a different signed-in mailbox cannot replace the original account. Local identity tests and a native build cover the change; live provider acceptance remains pending. The published test.4 download includes this improvement; test.1 remains unchanged.

- Native Mac app builds as Geoffrey `0.14.0` (build 30; published at the existing test.9 URL).
- The current [owner test download](desktop-test-download.md), `v0.14.0-desktop-test.9`, publishes build 30 with the GitHub sync, capability launch, multi-account chat, automation repairs, section-header feedback, the Start here task button, read-only chat email access, the local-day calendar correction, the private backup fix, neutral account icons, shorter setup path, optional backup, multi-account follow-up, and bundled runtimes. Its unauthenticated public download matches the tested ZIP. It remains ad-hoc signed, unnotarized, not marked latest, and has no production update feed. Manual approval supports owner testing; normal Gatekeeper acceptance and Dustin readiness remain blocked. Earlier test.1 first launch was blocked before the owner manually approved it and reached setup.
- Production release builds now fail before app rebuild/output creation when the requested signing identity is missing, ad-hoc, the wrong certificate type, malformed, revoked, or unmatched. Secret-free identity preflight checks and isolated regression tests pass. The checked Mac has zero valid identities; the owner’s Apple account shows an enrollment prompt.
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
- Native release packages use an explicit allowlist and pass sensitive-material checks. Repository ZIPs exclude owner `.release-evidence/` directories at any depth; both repository-bundle and native-payload checks reject injected evidence paths. An isolated committed-source test proves exclusion, package freshness, and rejection without reading the developer’s private files.
- The approved history cleanup removed 18 risky blobs, including contaminated nested ZIPs, from both distributed branches and removed the beta release/download/tag. The rewritten candidate and a fresh GitHub clone pass the direct and nested history audit with all risk counts zero. An owner-only recovery mirror is preserved outside this checkout, and this checkout now uses fresh clean Git metadata.
- Sampled old commit IDs remain accessible through GitHub, so server-side cached-object cleanup remains pending. Dustin is the only other installation; its old source checkout must transition before its next Git-based update. The archived Google OAuth file is an installed-app public-client configuration; its presence alone does not establish account compromise, and the owner deferred rotation. No credential was changed.
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
- Resolving Apple Developer Program enrollment/team access and installing the Developer ID Application identity needed for first-launch acceptance.
- Developer ID and notarized end-to-end update/rollback acceptance on a clean Mac; the updater and release tooling are implemented, but production signing credentials have not been exercised.
- Clean-Mac and pilot-account acceptance of the complete native first-run sequence; its state model, resume behavior, build, and dark-mode layout are locally proven.
- GitHub server-side cached-object cleanup and the eventual guided transition of Dustin’s old source checkout, described in [Git History Remediation Record](HISTORY-REMEDIATION.md). The branch rewrite, beta removal, and fresh-clone verification are complete.

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
