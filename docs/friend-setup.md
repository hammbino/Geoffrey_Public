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
   Outlook/Microsoft 365 is supported too; they only sign in with the mailbox
   they want Geoffrey to see.
   Geoffrey keeps asking whether to add another mailbox until they are done.
   If they make a mistake, they can type `back` or `cancel`.
7. Open Claude, Codex, or ChatGPT with the Geoffrey memory repo.
8. Paste the first prompt printed by the setup.
9. Run the first demo action, usually Inbox Rescue.
10. Continue with `./bin/geoffrey chief-of-staff --memory /path/to/memory-repo`
    to map the rest of the business tools, plugin needs, and first custom
    Geoffrey skills.

Helpful checks:

```bash
./bin/geoffrey dashboard
./bin/geoffrey first-win
./bin/geoffrey connect-tool
./bin/geoffrey first-run
./bin/geoffrey update-check
./bin/geoffrey update
```

Daily use after setup:

```text
Open Geoffrey from Applications.
```

Use **Brief me** for the daily command center, **Ask Geoffrey** for any request,
and **Adjust it** after a briefing if it needs to be shorter, more focused, or
weighted differently. Geoffrey saves that feedback in the person's private
memory for the next briefing.

Terminal is only needed for support or advanced use:

```text
Double-click Geoffrey.command on the Desktop.
```

Or:

```bash
Geoffrey
```

This opens Claude Code in the user's Geoffrey memory repo, starts with the daily
briefing and email/follow-up skills, and syncs new memory or skill changes with
GitHub before and after the session.

First proof of value:

```bash
./bin/geoffrey first-win
```

That lets them choose Daily Briefing, Inbox Rescue, Follow-Up Finder, or Open
Loops and launches Claude Code directly into the work.

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

Future updates:

```bash
cd ~/Geoffrey
./bin/geoffrey update
```

Geoffrey schedules a biweekly update check on Mac during setup. Every other
week it quietly checks GitHub. If no update exists, it says nothing. If a new
Geoffrey version is available, it asks before installing.

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
./bin/geoffrey chief-of-staff --memory /path/to/geoffrey-memory-repo
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
