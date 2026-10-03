# Geoffrey Multi-Email Setup

## Why This Exists

Claude's built-in connectors usually attach one Gmail account and one Microsoft
account. Geoffrey needs to work like a real assistant across several inboxes:
personal, work, billing, sales, old accounts, shared inboxes, or client-specific
mailboxes.

`geoffrey-mcp` solves that by making the mailbox an argument. Geoffrey connects
to one local MCP server, and that server can expose many accounts.

## What Geoffrey Can Do

- List connected mailboxes.
- Search a specific mailbox.
- Read a specific message after search.
- Create a draft from a specific account.
- List labels/folders.
- Label, archive, or mark read with approval boundaries.
- Read calendars.

Geoffrey does not send email. Drafts are saved for the human to review and send.

## Fast Setup

Run:

```bash
./bin/geoffrey setup
```

Or double-click:

```text
Install Geoffrey.command
```

The setup will:

1. Prepare `~/.geoffrey/`.
2. Install local connector dependencies.
3. Register Geoffrey's connector with Claude if the Claude CLI is available.
4. Offer to connect a mailbox.
5. Print the first white-glove prompt.

## Add Mail Later

```bash
./bin/geoffrey add-email
```

The flow keeps going until the user says they are done. Type `back` to restart
the current email step, or `cancel` to stop adding mailboxes.

List connected mailboxes:

```bash
./bin/geoffrey list-email
```

## Gmail

Gmail uses Geoffrey's bundled OAuth app by default.

What the setup asks for:

- Provider: `google`
- Short account id: `personal`, `work`, `billing`, etc.
- Purpose: what the account is for.

Example:

```bash
./bin/geoffrey add-email
```

The browser opens. Google will show an unverified-app warning because Geoffrey
is a private friends-and-family tool, not a verified marketplace app. Choose
Advanced, continue to Geoffrey, and approve the requested access.

Geoffrey confirms Gmail access before saving. If the bundled OAuth config is
missing, setup falls back to asking for a Google Desktop OAuth JSON file.

## Outlook / Microsoft 365

Outlook/Microsoft 365 support is built into Geoffrey through Microsoft Graph.
It can read mail, create drafts, read folders/categories, and read calendars.

Geoffrey includes `geoffrey-mcp/config/microsoft-oauth.json`, so setup uses the
bundled Microsoft app and the user only signs in.

The Entra setup guide is now an owner-maintenance fallback, not a normal friend
step:

```text
docs/outlook-setup.md
```

Then run:

```bash
./bin/geoffrey add-email
```

Choose Microsoft and paste the Application client ID when prompted.

## Account Storage

Account records live outside the repo:

```text
~/.geoffrey/accounts.json
```

The file is set to `chmod 600`. Refresh tokens are stored there; access tokens
are minted per run and cached only in memory.

Do not commit or share `~/.geoffrey/accounts.json`.

## How Geoffrey Should Use It

Geoffrey should always:

1. Call `list_accounts`.
2. Ask which account to use when ambiguous.
3. Search one account at a time.
4. Create drafts only after the user approves the content and sending account.
5. Never send email.
