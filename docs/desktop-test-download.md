# Geoffrey Mac Setup Test Download

[Download Geoffrey for Apple Silicon Macs](https://github.com/hammbino/Geoffrey_Public/releases/download/v0.14.0-desktop-test.2/Geoffrey-0.14.0-macOS-arm64-test.2.zip)

The current owner test is **0.14.0 (18)**, published as [v0.14.0-desktop-test.2](https://github.com/hammbino/Geoffrey_Public/releases/tag/v0.14.0-desktop-test.2). It requires an Apple Silicon Mac on macOS 14 or later. No GitHub account is needed to download it.

## Install or replace the previous test

1. Download the ZIP in your browser and open it in Downloads.
2. Quit Geoffrey if it is running.
3. Drag Geoffrey.app into Applications and replace the earlier test copy.
4. Open Geoffrey. If blocked, dismiss the warning, open System Settings > Privacy & Security, choose Open Anyway for Geoffrey, authenticate, and confirm Open.
5. Continue setup. Replacing the app does not reset accounts or private memory.

This uses the same public-download installation route planned for Dustin. It remains an owner test: the Dustin release gate has not passed. Manual approval is required for this ad-hoc-signed, unnotarized build; Developer ID signing, notarization, normal Gatekeeper acceptance, and signed update/rollback acceptance remain pending. Enrollment is deferred by the owner. The prerelease is not marked latest and includes no production update feed.

## Included fixes

- Direct Google/Microsoft sign-in without account-name or purpose questions.
- Provider-verified email names for new accounts and preservation of existing aliases.
- Locally created private memory stays selected if GitHub backup fails, with separate backup recovery guidance.
- Setup refresh follows creation even when a previous check is running.

## Verification

Built from commit `6f253116d20db633bdc14253a1f8529c57e3d27a`. Full local verification passed, including 52 connector tests, native checks, package safety, and strict ad-hoc signature verification. A ZIP round trip passed signature and payload checks. The published ZIP was downloaded without authentication and matched the tested bytes and GitHub asset digest.

- ZIP size: **11,282,203 bytes**.
- SHA-256: `4f2cb965b0b7ff42d3753653b7074324b561e0f9feeca27f207bc34e9645ef93`.
- [Download checksums](https://github.com/hammbino/Geoffrey_Public/releases/download/v0.14.0-desktop-test.2/SHA256SUMS.txt).

The package excludes owner accounts, private memory, owner OAuth configuration, recipient screenshots, Git metadata, and private release evidence. Real account connection and owner memory-setup acceptance remain pending.

## Earlier first-install test

The retained `v0.14.0-desktop-test.1` download was build 16 from `18bf94f3d80ef5ef0057c2d04c41f81dfb5e4fd0`, size 11,274,915 bytes, SHA-256 `18f44806ce4e38cfcc570e7cf4477c6ec41c4cf9df05d87f1f38e34dcd5143e8`. Gatekeeper blocked its first launch. The owner subsequently manually approved it and reached setup, exposing the account-form and memory-completion problems addressed in build 18. Manual approval does not establish normal Gatekeeper acceptance.
