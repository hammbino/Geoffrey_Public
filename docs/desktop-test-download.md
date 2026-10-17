# Geoffrey Mac First-Install Test Download

The owner/pilot test build is available on [GitHub Releases](https://github.com/hammbino/Geoffrey_Public/releases/tag/v0.14.0-desktop-test.1). No GitHub account is required to download it.

[Download Geoffrey for Apple Silicon Macs](https://github.com/hammbino/Geoffrey_Public/releases/download/v0.14.0-desktop-test.1/Geoffrey-0.14.0-macOS-arm64-test.1.zip)

## Install

1. Download the ZIP using your normal web browser.
2. Open the downloaded ZIP in Finder.
3. Drag **Geoffrey.app** into **Applications**.
4. Open **Geoffrey** from Applications and follow its setup guide.

This download is version **0.14.0 (16)** for **Apple Silicon / arm64** and requires **macOS 14 or later**. It was built from commit `18bf94f3d80ef5ef0057c2d04c41f81dfb5e4fd0`.

## Test-build boundary

This is an ad-hoc-signed development build. It is **not Developer ID signed or Apple notarized**; macOS may block launch. If it does, stop and record the exact message as an installation-test result. This is not proof of production Gatekeeper acceptance and is not a Dustin-ready release.

The prerelease is not marked as the latest production release and publishes no signed `update.json`. Geoffrey’s production install, update, rollback, and Dustin acceptance gates remain pending.

Existing shared Claude/GitHub sign-ins may be recognized on a previously used Mac. That does not mean Geoffrey has restored an old connected account or private-memory selection. The owner’s Geoffrey-only reset was performed separately; downloading the app does not itself reset local state.

## Verification

The app passed release-payload checks and strict ad-hoc signature verification after a ZIP round trip. The published asset was downloaded without authentication and matched the local verified bytes.

- ZIP size: **11,274,915 bytes**.
- SHA-256: `18f44806ce4e38cfcc570e7cf4477c6ec41c4cf9df05d87f1f38e34dcd5143e8`.
- [Download checksums](https://github.com/hammbino/Geoffrey_Public/releases/download/v0.14.0-desktop-test.1/SHA256SUMS.txt).

The package excludes owner accounts, private memory, owner OAuth configuration, recipient screenshots, Git metadata, and private release evidence.
