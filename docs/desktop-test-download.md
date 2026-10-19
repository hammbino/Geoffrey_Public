# Geoffrey Mac Setup Test Download

[Download Geoffrey for Apple Silicon Macs](https://github.com/hammbino/Geoffrey_Public/releases/download/v0.14.0-desktop-test.8/Geoffrey-0.14.0-macOS-arm64-test.8.zip)

The current owner test is **0.14.0 (24)**, published as [v0.14.0-desktop-test.8](https://github.com/hammbino/Geoffrey_Public/releases/tag/v0.14.0-desktop-test.8). It requires an Apple Silicon Mac on macOS 15 or later. No GitHub account is needed to download it.

## Install or replace the previous test

1. Download the ZIP in your browser and open it in Downloads.
2. Quit Geoffrey if it is running.
3. Drag Geoffrey.app into Applications and replace the earlier test copy.
4. Open Geoffrey. If blocked, dismiss the warning, open System Settings > Privacy & Security, choose Open Anyway for Geoffrey, authenticate, and confirm Open.
5. Continue setup. Replacing the app does not reset accounts or private memory.

This uses the same public-download installation route planned for Dustin. It remains an owner test: the Dustin release gate has not passed. Manual approval is required for this ad-hoc-signed, unnotarized build; Developer ID signing, notarization, normal Gatekeeper acceptance, and signed update/rollback acceptance remain pending. Enrollment is deferred by the owner. The prerelease is not marked latest and includes no production update feed.

## Included fixes

- Private GitHub backup setup accepts a genuinely empty repository even when GitHub reports a blank default branch. It checks actual Git refs and still refuses existing history.
- The bundled Git includes its macOS Keychain credential helper, allowing the packaged app to authenticate for private backup.
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

Built from commit `f179db81f39c131ef99cf7a39228ad90dc42a32a`. Full local verification passed, including 66 connector tests, native app/model checks, packaged first-use memory with a system-only PATH, package safety, and strict ad-hoc signature verification. The packaged Git authenticated to an empty private repository in a read-only check; no memory was uploaded during verification. A ZIP round trip passed signature checks. The public download matched the tested ZIP byte for byte.

- ZIP size: **184,287,172 bytes**.
- SHA-256: `0a5d598df55b69ebb1ca732a7b5161ef6534997645c60e437076c294e2066b8e`.
- [Download checksums](https://github.com/hammbino/Geoffrey_Public/releases/download/v0.14.0-desktop-test.8/SHA256SUMS.txt).

The package excludes owner accounts, private memory, owner OAuth configuration, recipient screenshots, Git metadata, and private release evidence. Real provider acceptance and a clean-Mac UI journey remain pending.

## Earlier first-install test

The retained `v0.14.0-desktop-test.1` download was build 16 from `18bf94f3d80ef5ef0057c2d04c41f81dfb5e4fd0`, size 11,274,915 bytes, SHA-256 `18f44806ce4e38cfcc570e7cf4477c6ec41c4cf9df05d87f1f38e34dcd5143e8`. Gatekeeper blocked its first launch. The owner subsequently manually approved it and reached setup, exposing the account-form and memory-completion problems addressed in build 18. Manual approval does not establish normal Gatekeeper acceptance.

Test.2 remains available as build 18 from `6f253116d20db633bdc14253a1f8529c57e3d27a`; test.3 is build 19 from `65dc92a46dd3246786d7facc7b798a959f6a5217` with the Claude success-feedback correction. Test.4 adds the damaged-credential removal and full-length storage fix. Test.5 is build 21 from `e57c29cb2caeab2a2a7e10482dbab844045dede3` with the native reconnect correction. Test.6 is build 22 from `bf45adc9e687480df77bb202ccbd2cc1244457dd` with the shorter setup path and bundled runtimes. Test.7 is build 23 from `33e33d2e1e26a6c1c574c9138b9201bfefaf2fc0` with neutral account icons.
