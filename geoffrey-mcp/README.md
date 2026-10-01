# geoffrey-mcp

Multi-account email for any MCP client.

Claude's built-in connectors hold **one** account each — one Gmail, one
Microsoft. This server fronts any number of mailboxes behind a single
connector, because the account is a tool argument rather than a property of the
connection.

## Tools

| Tool | Returns |
|---|---|
| `list_accounts` | Every connected mailbox: id, provider, address, purpose |
| `search_messages` | Summaries only — id, from, subject, date, snippet. Never bodies. |
| `get_message` | Full text of one message by id |

Every tool requires an explicit `account`. Omitting it is a validation error,
not a guess about which mailbox was meant.

`search_messages` deliberately returns no message bodies. Bodies come only from
an explicit `get_message` on one id — otherwise a single search floods the
context window, which degrades the model's reasoning and can exhaust a session
mid-task.

There is no send tool. See `docs/geoffrey-architecture.md`, rule 5.

## Credentials

`~/.geoffrey/accounts.json`, chmod 600 — outside the repo so it cannot be
committed by accident. Plain JSON: readable, portable, and yours.

Access tokens are never written to disk; only refresh tokens are stored, and
access tokens are minted per run and cached in memory.

## Connect a mailbox

The white-glove package includes Geoffrey's friends-and-family Gmail OAuth app
configuration. A recipient normally does not need to create a Google Cloud app.

```bash
npm install
npm run add-account -- --provider google --id work --purpose "work Gmail"
```

Expect an "unverified app" warning — Advanced → Go to Geoffrey (unsafe). The
script confirms the grant reaches the Gmail API before saving, so a token that
refreshes but cannot read mail fails loudly instead of silently.

If the bundled config is unavailable, pass `--secrets ~/Downloads/client_secret_XXX.json`
as a fallback.

Repeat per mailbox with a different `--id`.

## Use it

Register once, then it is available in every project:

```bash
claude mcp add --scope user geoffrey node /path/to/Geoffrey/geoffrey-mcp/src/index.js
```

## Test

```bash
node smoke-test.mjs
```

Exercises the tool list, a missing account, an unknown account, a real search,
and a real message fetch.

## Status

Slice 1: Google only. Microsoft needs an Entra app registration. The provider
interface in `src/providers/` is where that goes, and `src/auth.js` already
knows the Microsoft token endpoint.

This is a stdio server so it works locally today. Only the transport is
throwaway — the account registry and provider code move to the hosted Cloudflare
version unchanged.
