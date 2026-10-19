# Signed Desktop Updates

Geoffrey `0.14.0` contains an app-native update client. Development builds are
ad-hoc signed and intentionally cannot install updates. A production build must
have all three independent trust layers before the client will replace the app:

1. a manifest signed by Geoffrey's offline Ed25519 update key;
2. an archive whose byte count and SHA-256 digest match that signed manifest;
3. a replacement `com.geoffrey.assistant` app signed by the same Apple Developer
   ID team as the running app.

The app also requires HTTPS for the manifest, download, and all redirects. It
extracts into an owner-only staging folder, refuses unsafe archive paths and
symbolic links, validates the candidate again inside the update helper, and
keeps the prior signed app at
`~/Library/Application Support/Geoffrey/Updates/Previous/Geoffrey.app`.
Settings exposes that prior version as an explicit rollback action. Memory,
account metadata, and Keychain items live outside the app bundle and are not
replaced by an update or rollback.

## Current first-install blocker

The public `v0.14.0-desktop-test.1` app failed its owner first-launch test: Gatekeeper displayed an “Apple could not verify” dialog before onboarding could start. Local `spctl --assess --type execute` also rejected the ad-hoc build. ZIP integrity and ad-hoc code-signature validity are different checks from Apple publisher/notarization acceptance.

The checked Mac has zero valid signing identities. The owner’s developer account showed an enrollment prompt on October 18, 2026. To unblock distribution:

1. The owner signs into [Apple Developer Account](https://developer.apple.com/account/) and resolves [Developer Program enrollment](https://developer.apple.com/programs/enroll/) or access to an existing eligible team. The owner completes any agreement/payment directly with Apple.
2. Create or import a [Developer ID Application certificate](https://developer.apple.com/help/account/certificates/create-developer-id-certificates) with its private key on the signing Mac. Apple Development and Developer ID Installer identities do not satisfy app distribution signing.
3. Run `./scripts/check-mac-signing.sh`. To verify a specific certificate, set `GEOFFREY_CODESIGN_IDENTITY` to its exact public certificate name or fingerprint. Output contains status/counts, not private keys or certificate names.
4. The owner configures the notarytool Keychain profile through its interactive credentials flow. Never paste an Apple password, app-specific password, or private key into chat, release notes, or committed files.
5. Complete the existing update-key and release-notes setup below, build the signed/notarized archive, then test its actual browser download and first launch before presenting it as a normal install.

The production release builder now checks the requested Developer ID Application identity before rebuilding the app or creating release output. Missing, ad-hoc, wrong-type, malformed, revoked, or unmatched identities fail closed. A passing identity check does not prove Apple notarization, Gatekeeper acceptance, update acceptance, or Dustin release readiness.

## One-Time Release Setup

Generate the Ed25519 key once, writing the private half outside this repository:

```bash
./scripts/generate-update-signing-key.sh /absolute/private/location/geoffrey-update.key
```

Store the printed public key in the release environment. Back up the private
key in an owner-only secret store. Never commit either the private key or a copy
of it to Git, and never put it in an app or release archive.

Create an Apple `notarytool` Keychain profile separately, using Apple's supported
credentials flow. The release script deliberately requires notarization; it
does not offer an unsigned or unnotarized production mode.

## Build A Release

Prepare a reviewed plain-text release-notes file, then run:

```bash
GEOFFREY_CODESIGN_IDENTITY="Developer ID Application: Example (TEAMID)" \
GEOFFREY_UPDATE_PUBLIC_KEY="BASE64_PUBLIC_KEY" \
GEOFFREY_UPDATE_PRIVATE_KEY_FILE="/absolute/private/location/geoffrey-update.key" \
GEOFFREY_RELEASE_NOTES_FILE="/absolute/path/release-notes.txt" \
GEOFFREY_NOTARY_PROFILE="geoffrey-notary" \
./scripts/build-signed-mac-release.sh
```

The script builds with the public key embedded, applies a hardened Developer ID
signature, submits the app to Apple's notary service, staples and validates the
ticket, creates the final ZIP, then signs an exact JSON payload containing the
version, build, minimum macOS version, release notes, archive URL, byte count,
and SHA-256 digest. It writes the ZIP and `update.json` beneath
`build/releases/VERSION/` without overwriting an existing release directory.

Publish both files to the matching GitHub release. The app reads only
`https://github.com/hammbino/Geoffrey_Public/releases/latest/download/update.json`.
Before calling the release ready, install the previous signed version on a
clean Mac, update through Settings, confirm the new version and preserved state,
then use Settings to restore the previous version and confirm rollback.

## Current Evidence Boundary

The manifest verifier, version rules, HTTPS restriction, digest calculation,
packaged helper, publisher checks, release-notes UI, automatic daily check, and
rollback discovery are compiled and locally tested. No real Developer ID and
notarized update has yet completed this end-to-end acceptance sequence, so the
distribution gate remains open.
