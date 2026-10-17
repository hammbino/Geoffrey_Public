# Current Product Status

Updated: October 16, 2026

The current effort is the native Mac release for Dustin. The terminal interface is not the future product, but its state must be preserved. The authoritative scope, evidence, limitations, and release gate are in [Desktop Release Record](DESKTOP-RELEASE.md).

## Proven Now

- Native Mac app builds as Geoffrey `0.12.0` (build 14).
- Geoffrey's revised illustrated identity is packaged in native Mac icon sizes and appears in the sidebar as “Geoffrey — Your AI chief of staff”; the original portrait asset remains preserved.
- The Memory screen can build and refresh a versioned, secret-free recovery map covering approved private-memory skills, email/calendar connection definitions, Claude MCP/plugin definitions, hashes, Git repository metadata, and explicit reconnect requirements.
- A guided Memory-screen restore clones private GitHub memory into a new owner-only folder, rejects overwrites, credentials, symbolic links, unsupported maps, changed skill hashes, and unverified checkout artifacts, then restores only the verified memory pointer. A clean second-environment test proves credentials and connected-account state are not recreated, and a failed pointer update removes the staged clone.
- The app installs its versioned engine in `~/Library/Application Support/Geoffrey/engine`.
- Legacy setup discovery covers the Geoffrey workspace, account registry, current-memory pointer, private GitHub memory, and likely automation files.
- Migration creates a permission-restricted local backup and a secret-free inventory without deleting or relocating the old state.
- Ask Geoffrey streams Claude responses, records and resumes Claude session IDs, and preserves the visible conversation locally with `0600` permissions.
- Owners can stop an active request and see understandable thinking, connected-account, web, reading, and approved-change states.
- Claude sign-in status and login flow are surfaced through the app.
- Capability inventory combines Claude skills, plugins, and MCP servers.
- Improve Geoffrey summarizes Claude, email/calendar, private memory, GitHub, and capability readiness before recommending anything new.
- Missing setup and unhealthy capabilities route to targeted actions, including account repair, Claude or GitHub sign-in, disabled-plugin enablement, and MCP reconnection guidance.
- Improve Geoffrey places the outcome-first “Connect a business tool” action above the longer inventory of available capabilities.
- Release packages use an explicit allowlist and pass sensitive-material checks.
- A live authenticated two-turn Claude session successfully resumed the same session and recalled information from the first turn.
- Geoffrey's exact `stream-json` flags were verified against the installed Claude Code `2.1.301` event format.
- The Mac conversation interface has been visually inspected in the built app.
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
- Keychain-backed secret storage and connection repair.
- A signed, app-native updater that supersedes the initial legacy GitHub transition.

## Not Yet Proven

- Import and execution of Dustin's three-times-daily social briefing.
- Actual cloud execution while Dustin's Mac is off.
- End-to-end publication and import from a real Claude Routine using Dustin's actual briefing; the transport and importer are implemented and synthetically proven, but real cloud execution is not yet proven.
- Automatic background polling for cloud results; the pilot currently uses the visible Check results action.
- Real private-GitHub restore acceptance on a clean pilot Mac; isolated second-environment restore is automated and passing.
- Clean-Mac installation, Developer ID signing, notarization, Gatekeeper acceptance, and rollback.
- End-to-end migration against Dustin's actual machine.

## Readiness

This branch is a development milestone, not a Dustin release candidate. Dustin should not be involved until the release gate in the Desktop Release Record passes.
