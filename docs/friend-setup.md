# Friend Setup

## Easiest Path On Mac

1. Open the Geoffrey folder.
2. Double-click `Install Geoffrey.command`.
3. Follow the terminal prompts.
4. Let Geoffrey create the private memory repo.
5. Connect GitHub if you want the memory to travel across devices.
6. Connect email/calendar accounts if you want Geoffrey to see them. Gmail uses
   Geoffrey's bundled sign-in helper; continue through Google's unverified-app
   warning.
   Outlook/Microsoft 365 is supported too. If the package includes Geoffrey's
   Microsoft app config, they only sign in; otherwise use `docs/outlook-setup.md`.
7. Open Claude, Codex, or ChatGPT with the Geoffrey memory repo.
8. Paste the first prompt printed by the setup.
9. Run the first demo action, usually Inbox Rescue.
10. Continue with `./bin/geoffrey connectors` to walk through the rest of the
    business tools.

Helpful checks:

```bash
./bin/geoffrey status
./bin/geoffrey first-run
```

## Terminal Path

If Geoffrey is not downloaded yet, have them open Terminal and paste:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/hammbino/Geoffrey_Installer/main/install.sh)"
```

If Geoffrey is already downloaded:

```bash
cd /path/to/Geoffrey
./bin/geoffrey bootstrap
```

`bootstrap` checks for Claude Code, installs it if npm is available and the
user approves, registers Geoffrey with Claude, then starts setup. If Homebrew or
Node.js is missing, Geoffrey offers to install those too.

They do not need a GitHub account to download Geoffrey. During onboarding,
Geoffrey will help them create or sign into GitHub because Geoffrey's memory
lives in a private repo.
Geoffrey asks whether they already have GitHub. If not, it opens the free signup
page and waits while they create one.

Create just the memory/GitHub repo:

```bash
./bin/geoffrey memory --name "Friend Name" --business "Friend Business" --github friend-github --push
```

## What To Tell Them

```text
This is Geoffrey. It is an executive assistant setup that can remember context,
run projects, remember context in a private GitHub repo, and work across
multiple email accounts.

Geoffrey will also ask where the rest of your business work lives: files,
calendar, projects, CRM, billing, website, marketing/socials, chat, and
automations.

Use this command for the broader chief-of-staff setup:

```bash
./bin/geoffrey connectors
```

Run the installer, connect whichever email/calendar accounts you want Geoffrey
to see, create the memory repo, then open that memory repo in Claude, Codex, or
ChatGPT and paste the first prompt it prints.
```

## First Useful Action

After setup, run:

```text
Geoffrey, run Inbox Rescue.

Use every connected mailbox you can see. Look at the last 7 days. Find important
or unanswered client, prospect, billing, or scheduling messages. Group them by
urgency, draft replies for the top 3, and suggest a realistic plan for handling
the rest today. Do not send anything.
```

## First Prompt

```text
Use Geoffrey.

Onboard me with a white-glove setup.

Ask me no more than three questions at a time. First learn what I do, what is on
my plate, what applications I use, and which email/calendar accounts I want
Geoffrey to see. Then take one useful task off my plate before showing me any
detailed system map.
```
