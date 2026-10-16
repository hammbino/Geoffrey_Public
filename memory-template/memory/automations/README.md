# Geoffrey Automations

`manifest.json` is the portable, secret-free index of recurring work Geoffrey knows about. It belongs in the owner's private GitHub memory repository so the owner can move to another tool without losing workflow definitions.

Each workflow may record:

- a stable `id`, plain-language `name`, and `purpose`;
- `cadence.times` and an IANA `cadence.timezone`;
- whether execution prefers Claude cloud, this Mac, or automatic classification;
- capability names and local-path requirements, but never credentials;
- explicit owner approval and enabled state; and
- non-secret status such as the most recent or next run.

Tokens, OAuth records, API keys, message contents, and other secrets do not belong in this file. Geoffrey keeps local queue state under `~/.geoffrey/automations/queue.json`, outside GitHub.

Imported terminal-era files appear as review candidates first. Geoffrey does not create, duplicate, enable, or change a schedule merely because it discovered a file whose name suggests an automation.
