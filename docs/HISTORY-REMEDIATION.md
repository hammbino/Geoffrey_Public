# Git History Remediation Decision

Updated: October 17, 2026

## Decision

A coordinated Git history rewrite is required before Geoffrey is distributed beyond the current controlled pilot path.

The October 17 metadata-only audit confirmed that the current tree and release packages are clean, but reachable Git history still contains:

- 12 recipient-media blob objects totaling 4,753,953 bytes; and
- 2 private app-archive blob objects totaling 141,889,040 bytes.

The direct filename audit found no reachable files with known credential-bearing names. A deeper October 17 scan of all 74 reachable ZIP blobs, including nested ZIPs, found six archive blobs containing risky paths; four contained credential-named files with a nonempty OAuth `client_secret`. The published `v0.1.0-private-beta` download independently contained a nonempty OAuth client secret and recipient media. Treat that client secret as exposed and revoke or rotate it; a history rewrite cannot revoke a credential.

The proposed removal inventory contains 18 unique blobs: the 14 directly identified media/private-archive objects plus four additional contaminated bundle objects. Remove the nested carriers as well as the original files. No uninspectable ZIP was found in this scan. The bounded recursive audit now fails closed on corrupt, unsupported, encrypted nested, excessively large, or excessively deep ZIP contents instead of calling them clean.

The audit reports counts and byte totals only. It does not print recipient filenames, archive member names, credential values, or file contents. Credential-field inspection was performed separately in an owner-only local evidence folder, not in committed files.

## Why the rewrite is not automatic

Rewriting shared Git history changes commit identities and requires coordination with every clone, branch, tag, deployment source, and updater that references the repository. Running it silently from a development slice could strand an existing installation or cause removed objects to be reintroduced from another clone.

## Required coordinated procedure

1. Freeze pushes and identify every protected branch, tag, deployment reference, and active clone.
2. Create an owner-controlled recovery mirror that is not used for distribution.
3. Rotate any credential that may have been present in a historical archive.
4. Rewrite all distributed refs to remove the recipient media and private app archives.
5. Force-push the reviewed rewritten refs and delete obsolete remote tags or releases.
6. Re-clone every maintained working copy instead of merging old history.
7. Expire local and server-side unreachable objects according to the hosting provider's supported process.
8. Run `./scripts/audit-history-exposure.sh` and require `status=clean`.
9. Rebuild every release artifact and run `./scripts/verify.sh`.
10. Run `node scripts/check-dustin-release-gate.mjs` from the exact clean release commit; history remediation is only one of the required gates.

Until those steps are completed and recorded, the historical-exposure release gate remains open.

## Prepared recovery and scope

An owner-only recovery mirror was created outside the working checkout and verified with `git fsck --full`. Its push URL is disabled to prevent accidental republication. The private inventory, removal object IDs, downloaded beta, and proposed action manifest are kept under ignored `.release-evidence/history-remediation/`; those files must never enter a release package or Git commit.

Remote inventory found two unprotected branches (`main` and `codex/geoffrey-desktop-release`), one beta tag/release, no pull requests, and no forks. This observation does not identify existing clones or installations. The public beta release and asset must be removed as part of the approved cleanup; removing Git objects alone does not remove a GitHub release download.

The original working history and remote refs have not been rewritten. Before executing the prepared cleanup, the owner must explicitly override the earlier no-history-rewrite instruction, confirm the push freeze and affected clones/installations, and complete credential revocation/rotation. Then prepare and verify an isolated rewrite, compare both branch tips for unintended changes, recheck remote refs, and use exact ref leases for the reviewed publication. Do not merge an old clone into the cleaned history.

GitHub may retain cached commit views and other unreachable objects after a force-push. Follow [GitHub’s sensitive-data removal process](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository) for applicable server-side cleanup. Neither a passing local audit nor a force-push proves that every cached copy has been purged.
