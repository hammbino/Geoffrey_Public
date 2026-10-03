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
- Public Geoffrey clone or update

Then Geoffrey checks for:

- Node.js and npm
- Claude Code
- GitHub CLI and GitHub sign-in for memory
- Geoffrey's local email connector
- Gmail sign-in helper
- Microsoft OAuth config
- Biweekly Geoffrey update check
- One-word `Geoffrey` launcher

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
- Creating or signing into GitHub so Geoffrey can create the private memory repo

If they do not already have GitHub, Geoffrey opens the free signup page and
waits while they create the account.

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
- GitHub signed in
- Private Geoffrey memory repo created
- Gmail sign-in helper available, or Gmail already connected
- Microsoft OAuth config present

Then Geoffrey starts the white-glove setup.

To see what is ready or what needs attention:

```bash
./bin/geoffrey dashboard
```

To prove the system works immediately:

```bash
./bin/geoffrey first-win
```

To connect another business tool after email/GitHub:

```bash
./bin/geoffrey connect-tool
```

## Daily Use

After setup, open a new Terminal and type:

```bash
Geoffrey
```

That command opens Claude Code in the person's private Geoffrey memory repo,
starts with the daily briefing and email/follow-up skills, and syncs memory
changes with GitHub before and after the session.

## Future Updates

Because the installer uses a Git checkout when Git is available, later Geoffrey
features can be pulled in with:

```bash
cd ~/Geoffrey
./bin/geoffrey update
```

This does not overwrite private email tokens or the person's memory repo.

Geoffrey also schedules a Mac update check every other week. If a new Geoffrey
version is available, it asks before installing it.

To check manually:

```bash
cd ~/Geoffrey
./bin/geoffrey update-check
```

## Chief Of Staff Setup

After Geoffrey creates the private memory repo, run:

```bash
./bin/geoffrey chief-of-staff --memory /path/to/geoffrey-memory-repo
```

This asks what apps the owner uses, marks plugin and connector needs, writes the
operating rhythm, creates starter skills, and prints the first real-work prompt.
