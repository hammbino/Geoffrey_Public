# Terminal Bootstrap

Use this path for a friend who can open Terminal and paste one block.

## Copy/Paste Install

Open **Terminal**, paste this, then press Enter:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/hammbino/Geoffrey_Installer/main/install.sh)"
```

## What Bootstrap Does

The public installer checks for:

- Git
- Homebrew
- Public Geoffrey download

Then Geoffrey checks for:

- Node.js and npm
- Claude Code
- Geoffrey's local email connector
- Microsoft OAuth config

If Homebrew is missing, the installer offers to install it.

If Node.js/npm is missing, Geoffrey offers to install Node.js with Homebrew.

If Claude Code is missing and npm is available, Geoffrey offers to install it
with:

```bash
npm install -g @anthropic-ai/claude-code
```

Do not use `sudo` for the Claude Code install.

## What The Friend Still Has To Approve

Some steps must still be done by the person because they involve private
accounts:

- Signing in to Claude Code
- Signing in to Gmail or Outlook
- Approving Google or Microsoft permissions
- Creating or signing into GitHub later if they want Geoffrey memory synced to a
  private repo

## If The Download Fails

If the public download fails, use the zip path:

The zip path:

1. Unzip Geoffrey.
2. Open Terminal.
3. Drag the Geoffrey folder into Terminal after typing `cd `.
4. Press Enter.
5. Run:

```bash
./bin/geoffrey bootstrap
```

## Success Looks Like

Geoffrey should report:

- Claude Code installed
- Email connector installed
- Geoffrey registered with Claude
- Microsoft OAuth config present

Then Geoffrey starts the white-glove setup.
