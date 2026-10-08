# Start Here With Geoffrey

This is Geoffrey for Claude Desktop, Claude Code, Codex, and multi-account email.

If you want the easiest path on Mac, double-click:

```text
Install Geoffrey.command
```

If you prefer Terminal:

```bash
./bin/geoffrey bootstrap
```

That bootstrap checks for Claude Code, installs it if npm is available and you
approve, prepares Geoffrey's local email connector, offers to connect Gmail or
Outlook accounts, and prints the first prompt.

If Geoffrey is not downloaded yet, use the copy/paste terminal setup in
[docs/terminal-bootstrap.md](docs/terminal-bootstrap.md).

For a friend using Terminal, print the handoff command with:

```bash
./bin/geoffrey share
```

They do not need a GitHub account to download Geoffrey. During onboarding,
Geoffrey will help them create/sign into GitHub because Geoffrey's memory lives
in a private repo.
Geoffrey asks whether they already have GitHub. If not, it opens the free signup
page and waits while they create one.

## Daily Use

After setup, open **Geoffrey** from Applications. Start with **Brief me** for a
morning briefing, or use **Ask Geoffrey** to request help in plain language.
After a briefing, choose **Helpful** or **Adjust it** so Geoffrey can make the
next briefing more relevant.

The following are support and advanced options, not the normal daily path.

Double-click this file on the Desktop:

```text
Geoffrey.command
```

Or open a new Terminal and type:

```bash
Geoffrey
```

Both start Claude Code inside the private Geoffrey memory repo. Geoffrey reads
the current tools, chief-of-staff map, daily briefing skill, inbox rescue skill,
follow-up skill, and any new skills that were added.

The launcher syncs the memory repo with GitHub before Claude opens and again
after Claude closes, so added notes, preferences, projects, and skills travel
with the user.

To prove Geoffrey works immediately:

```bash
cd ~/Geoffrey
./bin/geoffrey first-win
```

To see what is ready or stuck:

```bash
cd ~/Geoffrey
./bin/geoffrey dashboard
```

To connect the next business tool after email/GitHub:

```bash
cd ~/Geoffrey
./bin/geoffrey connect-tool
```

Future Geoffrey updates are simple:

```bash
cd ~/Geoffrey
./bin/geoffrey update
```

Geoffrey schedules a biweekly Mac update check during setup. Every other week
it quietly checks GitHub. If no update exists, it says nothing. If a new
Geoffrey version is available, it asks before it installs anything.

To check sooner:

```bash
cd ~/Geoffrey
./bin/geoffrey update-check
```

Geoffrey also creates a private GitHub-backed memory repo. That repo holds the
person's `CLAUDE.md` brain and `memory/` files, so Geoffrey can remember and
continue work across devices.

For Gmail, Geoffrey uses the bundled friends-and-family OAuth app. Google will
show an unverified-app warning; click Advanced, then continue to Geoffrey.

Outlook/Microsoft 365 is supported through Microsoft Graph. Geoffrey includes
the Microsoft sign-in helper, so the user just signs in with the mailbox they
want Geoffrey to see.

## First Prompt

Paste this into Claude, Codex, or ChatGPT with the generated Geoffrey memory
repo open. If you have not created the memory repo yet, use this setup folder.

```text
Use Geoffrey.

Onboard me with a white-glove setup.

Ask me no more than three questions at a time. First learn what I do, what is on
my plate, what applications I use, and which email/calendar accounts I want
Geoffrey to see. Then take one useful task off my plate before showing me any
detailed system map.
```

## Why Geoffrey Handles Multiple Email Accounts

Claude's normal connectors are limited by account. Geoffrey includes
`geoffrey-mcp`, a local connector that can expose multiple Gmail and Outlook
accounts at once. Every mailbox gets a short id like `personal`, `work`,
`billing`, or `sales`, and Geoffrey must explicitly choose the account for each
email/calendar action.

Geoffrey can create drafts, but it does not send email.

## First Useful Action

After setup, run Inbox Rescue:

```text
Geoffrey, run Inbox Rescue.

Use every connected mailbox you can see. Look at the last 7 days. Find important
or unanswered client, prospect, billing, or scheduling messages. Group them by
urgency, draft replies for the top 3, and suggest a realistic plan for handling
the rest today. Do not send anything.
```

## Best Path For A Handoff

Use the one-file Claude plugin:

```text
dist/Geoffrey-Claude-Plugin.zip
```

That one file installs the Geoffrey skill bundle. The individual skill ZIPs are included only as a fallback.

Geoffrey should feel like relief for whoever receives it. It should not make a busy person manage a new onboarding project. It should ask a few practical questions, take one useful task off their plate, and quietly learn what to handle next.

For Mauricio, the current assistant baseline is Viktor.

## White-Glove Questions

Geoffrey should start with only three:

1. What do you do, and what kind of work do you wish Geoffrey would take off
   your plate first?
2. What is one real thing on your plate today that you would love not to carry?
3. Which applications hold your work right now?

Then Geoffrey asks only relevant follow-ups about email, calendar, chat, files,
project tools, CRM, money, website/content, marketing/socials, AI, and automations.

For the broader tool setup, run:

```bash
./bin/geoffrey chief-of-staff --memory /path/to/geoffrey-memory-repo
```

That creates the owner's tool map, plugin plan, operating rhythm, and first
custom Geoffrey skills inside the memory repo.

## Path A: Claude Desktop

1. Open Claude Desktop and sign in.
2. Open Settings.
3. Turn on Code execution and file creation if it is not already on.
4. Go to Customize > Plugins.
5. Choose the upload option.
6. Upload:

```text
dist/Geoffrey-Claude-Plugin.zip
```

7. Open the installed Geoffrey plugin and make sure its skills are enabled.
8. Start a new Claude chat.

First prompt:

```text
Use the Geoffrey plugin and onboard me.

I am busy and want to reduce load, mental fatigue, and process. Ask me no more than three questions, then take one useful task off my plate.
```

Mauricio-specific prompt:

```text
Use the Geoffrey plugin and onboard me.

I currently use Viktor as my assistant. I am busy and want to reduce load, mental fatigue, and process. Ask me no more than three questions to understand what Viktor handles and what is weighing on me today. Then take one useful task off my plate.
```

## Path B: Claude Code

Open this folder in Claude Code:

```bash
cd /path/to/Geoffrey
claude
```

Claude Code should read `CLAUDE.md` and discover project skills from `.claude/skills/`.

Code test:

```text
/recipient-onboarding I am handing Geoffrey to a busy business owner. Start with no more than three questions, then help with one useful task immediately.
```

Optional business pack test:

```text
/business-owner-oslo I run a small consulting business. I get calls but they stall after proposals. What should I fix first?
```

## Fallback: Individual Skill Uploads

If plugin upload is not available on the account, upload each skill ZIP from:

```text
dist/claude-skills/
```

Upload one at a time:

```text
geoffrey.zip
execute-and-verify.zip
context-management.zip
authority-management.zip
geoffrey-onboarding.zip
business-owner-oslo.zip
recipient-onboarding.zip
```

Then start a fresh chat with:

```text
Use the Geoffrey skill and onboard me.
```

## What Should Happen

- Claude should use Geoffrey as the main assistant operating loop.
- Claude should ask no more than three practical questions at once.
- Claude should help with one real task before presenting any detailed map.
- Claude should quietly capture the recipient's current assistant or manual-work baseline.
- Claude should identify what Geoffrey can do now, what needs access, what needs an example, and what needs build work.
- Claude should state approval boundaries simply before risky actions.

## If Something Fails

- In Claude Desktop, make sure Code execution and file creation is enabled.
- In Claude Desktop, use the Plugins page first; use individual Skills upload only as a fallback.
- In Claude Desktop, start a fresh chat and begin with `Use the Geoffrey plugin and onboard me`.
- In Claude Code, restart from the Geoffrey folder if `/recipient-onboarding` is not available.
- On a Team or Enterprise plan, an owner may need to enable Plugins or Skills for the organization first.

## Handoff Expectations

Geoffrey is ready for a recipient when:

1. The recipient can install Geoffrey or has someone install it once.
2. Geoffrey has completed one real useful task.
3. The recipient has accepted or corrected the output.
4. Geoffrey knows the highest-value current baseline workflows.
5. Approval boundaries are clear enough to proceed safely.
6. The next easiest load-reducing task is identified.

If those are not true yet, Geoffrey should keep helping with the next useful task instead of presenting a process.

## Package Check

This check is for the owner or a developer helper:

```bash
./scripts/check-claude-setup.sh
```

## Important Boundary

The `reference/` folder is research material only. Do not copy or redistribute reference material as Geoffrey source. The handoff ZIP excludes this folder by default.
