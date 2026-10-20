# Geoffrey Mac Setup Test Download

[Download Geoffrey for Apple Silicon Macs](https://github.com/hammbino/Geoffrey_Public/releases/download/v0.14.0-desktop-test.9/Geoffrey-0.14.0-macOS-arm64-test.9.zip)

The current test is **0.14.0 (30)**, published as [v0.14.0-desktop-test.9](https://github.com/hammbino/Geoffrey_Public/releases/tag/v0.14.0-desktop-test.9). The existing download URL was updated in place on October 19, 2026; a new download contains build 30. It requires an Apple Silicon Mac on macOS 15 or later. No GitHub account is needed to download it.

## Install or replace the previous test

1. Download the ZIP in your browser and open it in Downloads.
2. Quit Geoffrey if it is running.
3. Drag Geoffrey.app into Applications and replace the earlier test copy.
4. Open Geoffrey. If blocked, dismiss the warning, open System Settings > Privacy & Security, choose Open Anyway for Geoffrey, authenticate, and confirm Open.
5. Continue setup, or run Brief me for a new briefing after relaunch. Replacing the app does not reset accounts or private memory. A ZIP downloaded before the update remains the older build; download again to get build 30.

This uses the same public-download installation route planned for Dustin. It remains an owner test: the Dustin release gate has not passed. Manual approval is required for this ad-hoc-signed, unnotarized build; Developer ID signing, notarization, normal Gatekeeper acceptance, and signed update/rollback acceptance remain pending. Enrollment is deferred by the owner. The prerelease is not marked latest and includes no production update feed.

## Included fixes

- Run/Use buttons beside ready capabilities, with a task field and progress/results in Ask Geoffrey. Selected skill instructions are supplied directly. Chat opens at the latest messages and avoids a macOS text-selection rendering freeze.
- Fresh multi-account chat routing through Geoffrey's own reader, with the current account registry and strict isolation from separate Claude Gmail connections. Google and Microsoft accounts remain available together.
- Clear automation connection states, reliable review, preserved cloud links on edit, multiple daily provider links, validated result imports, and Delete that retains source files and prior results. Briefing feedback is no longer mistaken for recurring work. Each owner still connects and approves their own cloud schedules.

- Feedback beside each section header, with separate Good, Bad, More like this, and optional notes for every item inside its panel. The panel stays open between saves; saved feedback can be changed or cleared.
- A Do this button under Start here that starts the selected task and opens Ask Geoffrey for progress, questions, and results.
- Chat uses fresh connected-account context, the current local date, and a temporary read-only reader for existing Geoffrey email/calendar connections. It does not require a separate Claude Gmail connector approval. Only specific reading tools are preapproved; mailbox changes and draft creation are excluded from that reader. Tool denials produce a retryable error instead of an answer built from stale briefings.
- Briefings use the current local calendar day and retain event dates and end times. Tomorrow's meetings, cancelled events, and declined events are excluded; failed or incomplete reads cannot establish free time.

- Private GitHub backup setup accepts a genuinely empty repository even when GitHub reports a blank default branch. It checks actual Git refs and still refuses existing history.
- GitHub backup, restore, and cloud-result import reuse Geoffrey's existing GitHub CLI sign-in, overriding inherited Git credential helpers per process without changing global settings. Sync shows progress and connected-backup status correctly.
- Account icons use the same neutral color for Gmail and Outlook. Provider names and email addresses identify each account; green and orange indicate connection status.
- A shorter setup path through Claude sign-in, one or more healthy Google/Microsoft accounts, and local private memory.
- An immediate Add another account action; GitHub backup is optional and retryable from Memory.
- Bundled Node, Claude, Git, and GitHub CLI runtimes, with setup checks that do not depend on developer tools installed on the Mac.
- More reliable command cancellation, setup refresh, and backup failure recovery.

- Remove or reconnect damaged Keychain entries without parsing the old credential first.
- Store full credentials with a bounded native stdin writer and require exact read-back before marking them connected.
- Show a removal-specific failure message. After updating, retry Remove, or reconnect if you want to keep the account.

- Successful Claude sign-in updates readiness without displaying a misleading attention alert; failures retain recovery guidance.

- Direct Google/Microsoft sign-in without account-name or purpose questions.
- Provider-verified email names for new accounts and preservation of existing aliases.
- Locally created private memory stays selected if GitHub backup fails, with separate backup recovery guidance.
- Setup refresh follows creation even when a previous check is running.

## Verification

Built from commit `1970cfa8c29cf9b593688d104012058bd81a488d`. Full local verification passed, including 92 engine tests, native app/model checks, runtime checks, archive freshness, historical-exposure audit, and package safety. ZIP extraction retained its strict ad-hoc signature and exact tested bytes, and fresh local-memory setup passed with only bundled runtimes and macOS utilities. Live checks verified private GitHub backup without a password prompt, selected-skill launch, and chat enumerating five mailboxes across Google and Microsoft without mail changes. Two owner-approved cloud delivery tests produced validated results in Geoffrey. These checks do not establish Dustin's live migration or clean-Mac UI acceptance. The unauthenticated public download matched the tested ZIP byte for byte.

- ZIP size: **185,912,658 bytes**.
- SHA-256: `15fbf140a83663e2652f661dd47127d6f436cb71a5772a1380d23f392260f796`.
- [Download checksums](https://github.com/hammbino/Geoffrey_Public/releases/download/v0.14.0-desktop-test.9/SHA256SUMS.txt).

The package excludes owner accounts, private memory, owner OAuth configuration, recipient screenshots, Git metadata, and private release evidence. Dustin's provider acceptance and a clean-Mac UI journey remain pending.

## Earlier first-install test

The retained `v0.14.0-desktop-test.1` download was build 16 from `18bf94f3d80ef5ef0057c2d04c41f81dfb5e4fd0`, size 11,274,915 bytes, SHA-256 `18f44806ce4e38cfcc570e7cf4477c6ec41c4cf9df05d87f1f38e34dcd5143e8`. Gatekeeper blocked its first launch. The owner subsequently manually approved it and reached setup, exposing the account-form and memory-completion problems addressed in build 18. Manual approval does not establish normal Gatekeeper acceptance.

Test.2 remains available as build 18 from `6f253116d20db633bdc14253a1f8529c57e3d27a`; test.3 is build 19 from `65dc92a46dd3246786d7facc7b798a959f6a5217` with the Claude success-feedback correction. Test.4 adds the damaged-credential removal and full-length storage fix. Test.5 is build 21 from `e57c29cb2caeab2a2a7e10482dbab844045dede3` with the native reconnect correction. Test.6 is build 22 from `bf45adc9e687480df77bb202ccbd2cc1244457dd` with the shorter setup path and bundled runtimes. Test.7 is build 23 from `33e33d2e1e26a6c1c574c9138b9201bfefaf2fc0` with neutral account icons.

Test.8 remains available as build 24 from `f179db81f39c131ef99cf7a39228ad90dc42a32a`, including the private-backup fix and bundled Git Keychain credential helper. Its ZIP is 184,287,172 bytes with SHA-256 `0a5d598df55b69ebb1ca732a7b5161ef6534997645c60e437076c294e2066b8e`.

Test.9 originally served build 26 from `d0a433b2a68f99e8b7b55acb06916c277a075ff4`, size 184,334,789 bytes, SHA-256 `255b04d768c2ee0b4f3afb91f53e7ebead6552c66e2131de40b906bf44541251`. Its tag and assets were subsequently updated to build 28 from `4e4d0ad9cdb919e514fc1ce5485991704aa1f174` (184,358,640 bytes, SHA-256 `875b0bb80f970170aa0138987859eacee598dd8694e12e058f9c1bbf71640dd1`), and then build 30 while preserving the direct-download URL. Both previous packages are retained locally for recovery.
