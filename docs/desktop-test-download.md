# Geoffrey Mac First-Install Test Download — Launch Blocked

**Confirmed first-install failure:** the owner’s browser-downloaded app was blocked by macOS Gatekeeper before first-run setup. The native Gatekeeper assessment also rejects the development app. This download is retained to reproduce that failure; a Developer ID-signed, notarized replacement is required for normal first-install acceptance.

The owner/pilot test build is available on [GitHub Releases](https://github.com/hammbino/Geoffrey_Public/releases/tag/v0.14.0-desktop-test.1). No GitHub account is required to download it.

[Download Geoffrey for Apple Silicon Macs](https://github.com/hammbino/Geoffrey_Public/releases/download/v0.14.0-desktop-test.1/Geoffrey-0.14.0-macOS-arm64-test.1.zip)

## Reproduce the recorded installation test

1. Download the ZIP using your normal web browser.
2. Open the downloaded ZIP in Finder.
3. Drag **Geoffrey.app** into **Applications**.
4. Open **Geoffrey** from Applications and follow its setup guide.

This download is version **0.14.0 (16)** for **Apple Silicon / arm64** and requires **macOS 14 or later**. It was built from commit `18bf94f3d80ef5ef0057c2d04c41f81dfb5e4fd0`.

## Test-build boundary

This is an ad-hoc-signed development build. It is **not Developer ID signed or Apple notarized**; macOS has blocked the tested launch. The owner supplied the “Apple could not verify” dialog as failure evidence; first-run setup and connected-account testing have not started through this download. This is not proof of production Gatekeeper acceptance and is not a Dustin-ready release.

The prerelease is not marked as the latest production release and publishes no signed `update.json`. Geoffrey’s production install, update, rollback, and Dustin acceptance gates remain pending.

Existing shared Claude/GitHub sign-ins may be recognized on a previously used Mac. That does not mean Geoffrey has restored an old connected account or private-memory selection. The owner’s Geoffrey-only reset was performed separately; downloading the app does not itself reset local state.

## Verification

The app passed release-payload checks and strict ad-hoc signature verification after a ZIP round trip. The published asset was downloaded without authentication and matched the local verified bytes.

- ZIP size: **11,274,915 bytes**.
- SHA-256: `18f44806ce4e38cfcc570e7cf4477c6ec41c4cf9df05d87f1f38e34dcd5143e8`.
- [Download checksums](https://github.com/hammbino/Geoffrey_Public/releases/download/v0.14.0-desktop-test.1/SHA256SUMS.txt).

The package excludes owner accounts, private memory, owner OAuth configuration, recipient screenshots, Git metadata, and private release evidence.

## Next prerequisite

The checked Mac currently has zero valid signing identities. The owner’s Apple Developer account showed a **Join the Apple Developer Program / Enroll today** prompt on October 18, 2026. Enrollment or an existing eligible developer team must be resolved before issuing the Developer ID Application signing identity and setting up notarization. A free Apple developer login is not evidence that these distribution capabilities are available.

Run `./scripts/check-mac-signing.sh` to check local Developer ID Application identity availability without printing certificate names. Its success establishes only certificate availability, not notarization or Gatekeeper acceptance. See [signed release setup](desktop-updates.md).
