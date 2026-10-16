# Geoffrey Automations

`manifest.json` is the portable, secret-free index of recurring work Geoffrey knows about. It belongs in the owner's private GitHub memory repository so the owner can move to another tool without losing workflow definitions.

Each workflow may record:

- a stable `id`, plain-language `name`, and `purpose`;
- an owner-approved `task` that tells Geoffrey what read-only result to produce;
- `cadence.times` and an IANA `cadence.timezone`;
- whether execution prefers Claude cloud, this Mac, or automatic classification;
- a non-secret cloud routine/deployment reference and `verified_at` timestamp only after Geoffrey has confirmed that it is active;
- capability names and local-path requirements, but never credentials;
- explicit owner approval and enabled state; and
- non-secret status such as the most recent or next run.

Tokens, OAuth records, API keys, message contents, and other secrets do not belong in this file. Geoffrey keeps local queue state under `~/.geoffrey/automations/queue.json`, outside GitHub. Non-secret run history and owner-ready results are stored under `memory/automations/` so they travel with private memory.

Local execution always uses Claude's read-only plan permission mode. A recurring workflow cannot send, publish, spend, delete, change access, or modify an outside system. Those consequential actions require a separate, current owner approval.

Imported terminal-era files appear as review candidates first. Geoffrey does not create, duplicate, enable, or change a schedule merely because it discovered a file whose name suggests an automation.

The Geoffrey Mac app is the supported place to create or review these definitions. An owner can save a disabled draft or explicitly approve the proposed cadence and route. Saving an approved cloud-capable definition records intent only: it does not create a Claude Routine, and Geoffrey must not call it active until the supported cloud deployment is connected and verified.

For Claude Routines, `execution.routine_url` may store a clean non-secret Claude detail link. `deployment_state: connected` means the owner recorded the Routine after reviewing its cadence and included connectors; it is not proof of a successful run. Geoffrey records `active`, `verified_at`, and `execution.verification.method: owner_reviewed_run` only after the owner opens a Run now session, inspects the actual result, and records its non-secret Claude session link. Routine API trigger tokens, bearer headers, and other credentials never belong here.

Each connected cloud workflow has a deterministic `claude/geoffrey-results-...` branch. A Routine may append one strict JSON envelope under `memory/automations/cloud-inbox/<workflow-id>/` on that branch. Geoffrey fetches that exact branch, reads only bounded envelope files, validates their workflow identity, timestamps, source, status, and size, redacts common credential forms, and copies accepted owner-ready results into `memory/automations/results/` plus bounded portable history. It never checks out or merges the cloud branch. Invalid envelopes are reported and ignored. The branch is transport, while the normal private-memory branch remains the portable source of truth.
