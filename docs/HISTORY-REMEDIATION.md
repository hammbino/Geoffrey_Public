# Git History Remediation Record

Updated: October 17, 2026

## Current result

The owner approved the coordinated cleanup after confirming that the owner is the only developer and Dustin is the only other Geoffrey installation. Both distributed branches now have clean rewritten history. The contaminated `v0.1.0-private-beta` release, its downloadable asset, and its tag have been removed.

The strengthened direct-path and bounded recursive-ZIP audit reports `status=clean` from the isolated candidate, a fresh GitHub clone, and the adopted working checkout:

- recipient-media blobs: 0;
- private app-archive blobs: 0;
- direct credential-path blobs: 0;
- contaminated ZIP blobs: 0;
- ZIP blobs with credential-named members: 0; and
- uninspected ZIP blobs: 0.

This is a clean reachable-history result. It is not proof that GitHub has purged cached or unreachable objects, and it does not establish Dustin release readiness.

## What was removed and preserved

The preparation audit identified 12 recipient-media blobs, two private app-archive blobs, and four additional historical bundle blobs that embedded risky material: 18 unique blobs in total. The nested audit found six contaminated ZIP blobs, including the two private app archives. The published beta independently contained recipient media and a Google OAuth client configuration.

An owner-only recovery mirror was created outside the working checkout, verified with `git fsck --full`, and given a disabled push URL. Private inventories, removal object IDs, the original downloaded beta, commit mappings, and verification records remain under ignored `.release-evidence/history-remediation/`; they are excluded from distribution. Original working Git metadata was also retained in a private external recovery directory with pushing disabled.

A separate mirror was rewritten with git-filter-repo 2.47.0 using the reviewed blob-ID inventory. The obsolete beta tag was omitted. Branch-tip comparison proved that retained files—including source code—were byte-identical to their originals. The release branch tip had no file removals. The older `main` tip lost 15 selected private/contaminated files; two obsolete safe ZIP versions that resurfaced during filtering were removed in a follow-up `main` commit to prevent an accidental artifact rollback.

The release candidate passed `./scripts/verify.sh` in a fresh isolated checkout with lockfile-pinned dependencies. Both branch updates and beta-tag deletion were published atomically with exact expected-old-ref leases. A fresh clone from GitHub matched both verified branch IDs, passed `git fsck --full`, and reported clean direct/nested history. This working checkout then adopted the fresh clone’s Git metadata after verifying that its working tree was clean and its file tree identical. No private account or memory files were moved or changed.

## OAuth credential clarification

The archived configuration was positively identified as a Google **installed-app** OAuth client configuration. Google documents desktop applications as public clients that cannot keep a client secret confidential. A nonempty `client_secret` in that configuration alone does not establish account compromise or make immediate rotation a prerequisite for this history cleanup. The owner asked to leave the credential unchanged; no rotation, revocation, or account reconnection was performed.

This corrects the preparation-stage recommendation to rotate solely because a client-secret field was present. Client-type review and token exposure are different questions. No account-compromise claim is made here. Geoffrey’s packaging policy continues to exclude owner account and OAuth configuration files from release artifacts.

Reference: [Google OAuth 2.0 for Desktop Apps](https://developers.google.com/identity/protocols/oauth2/native-app).

## Remaining server cleanup

After the rewrite, GitHub’s API still served the sampled first-changed old commit and the old release-branch tip by their original IDs. Changing branch refs and deleting a release does not by itself expunge every cached view or unreachable object.

An owner-reviewable GitHub Support request is prepared in the private evidence folder. It includes the repository, first-changed commit mapping, the absence of pull requests and forks at inventory time, and the cleanup/verification performed. It contains no recipient media or credential values. It has not been submitted.

Follow [GitHub’s sensitive-data removal process](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository) for applicable server-side dereferencing, cached-view removal, and garbage collection. Support determines the available removal process. Do not call the server purge complete until it is confirmed.

## Dustin’s existing installation

No change was made to Dustin’s Mac. Do not ask him to take a desktop release before the Dustin release gate passes.

His old source checkout must not be merged or pushed into the cleaned repository. Its Git-based updater uses a fast-forward-only pull, so it needs a guided checkout transition before its next source update. Before that transition, back up his existing installation, discover and preserve the actual account registry, Keychain state, memory pointer, and private-memory repository, and use a fresh source checkout that selects the existing state. Keep the old source copy offline with pushing disabled until acceptance is complete. Do not blindly delete or relocate his private memory based on an assumed path.

## Completion checks

- [x] Preserve an owner-controlled recovery mirror with pushing disabled.
- [x] Review direct objects, nested bundles, and the published beta privately.
- [x] Obtain owner authorization and identify maintained users/developers.
- [x] Rewrite both distributed branches and compare retained source trees.
- [x] Remove the contaminated beta release, asset, and tag.
- [x] Publish with exact ref leases and verify a fresh GitHub clone.
- [x] Adopt clean Git metadata in the active development checkout.
- [ ] Obtain applicable GitHub server-side cached-object cleanup confirmation.
- [ ] Transition Dustin’s old source checkout before its next Git update.
- [ ] Complete the remaining Dustin release acceptance and evidence gates.
