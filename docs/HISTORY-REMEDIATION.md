# Git History Remediation Decision

Updated: October 17, 2026

## Decision

A coordinated Git history rewrite is required before Geoffrey is distributed beyond the current controlled pilot path.

The October 17 metadata-only audit confirmed that the current tree and release packages are clean, but reachable Git history still contains:

- 12 recipient-media blob objects totaling 4,753,953 bytes; and
- 2 private app-archive blob objects totaling 141,889,040 bytes.

No files with the known credential-bearing names checked by the release policy remain reachable in history. This does not prove that the opaque historical app archives never contained credentials, so any credential known to have entered those archives must be rotated before distribution.

The audit reports counts and byte totals only. It does not print recipient filenames or file contents.

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

Until those steps are completed and recorded, the historical-exposure release gate remains open.
