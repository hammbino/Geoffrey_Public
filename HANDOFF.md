# Geoffrey Handoff

## What This Is

Geoffrey is packaged for Claude Desktop and Claude Code.

The product vision is Geoffrey: a practical AI operating assistant that reduces load, owns outcomes, remembers useful context, respects approval boundaries, verifies its work, and expands through optional packs.

For every recipient, Geoffrey should make onboarding feel light. It should ask a few practical questions, do one useful task quickly, and quietly maintain a handoff packet behind the scenes.

For Mauricio, the current baseline is Viktor.

Primary install file:

```text
dist/Geoffrey-Claude-Plugin.zip
```

Primary terminal handoff:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/hammbino/Geoffrey_Installer/main/install.sh)"
```

The friend does not need a GitHub account to download Geoffrey. During
onboarding, Geoffrey helps them create/sign into GitHub because Geoffrey's
memory lives in a private repo.
Geoffrey asks whether they already have GitHub and opens signup if they do not.

## What Is Ready

- One-file Claude plugin: `dist/Geoffrey-Claude-Plugin.zip`
- Claude Desktop fallback skill ZIPs: `dist/claude-skills/`
- Claude Code project memory: `CLAUDE.md`
- Claude Code project skills: `.claude/skills/`
- Plugin source folder: `plugins/geoffrey/`
- Reusable quiet packet template: `docs/handoff-packet-template.md`
- Mauricio starter packet: `docs/mauricio-onboarding-packet.md`
- Product docs: `docs/`
- Canonical Core skills: `core/skills/`
- Optional packs: `packs/`
- Package checker: `scripts/check-claude-setup.sh`

## Path A: Claude Desktop

In Claude Desktop:

1. Open Settings.
2. Enable Code execution and file creation.
3. Go to Customize > Plugins.
4. Choose the upload option.
5. Upload:

```text
dist/Geoffrey-Claude-Plugin.zip
```

6. Open the installed Geoffrey plugin and make sure its skills are enabled.
7. Start a new Claude chat.

Generic onboarding prompt:

```text
Use the Geoffrey plugin and onboard me.

I am busy and want to reduce load, mental fatigue, and process. Ask me no more than three questions, then take one useful task off my plate.
```

Mauricio onboarding prompt:

```text
Use the Geoffrey plugin and onboard me.

I currently use Viktor as my assistant. I am busy and want to reduce load, mental fatigue, and process. Ask me no more than three questions to understand what Viktor handles and what is weighing on me today. Then take one useful task off my plate.
```

## Path B: Claude Code

Terminal bootstrap checks for Claude Code and offers to install it:

```bash
./bin/geoffrey bootstrap
```

Open the Geoffrey folder in Claude Code:

```bash
cd /path/to/Geoffrey
claude
```

Claude Code should load `CLAUDE.md` and discover the project skills under `.claude/skills/`.

Code smoke test:

```text
/recipient-onboarding I am handing Geoffrey to a busy business owner. Start with no more than three questions, then help with one useful task immediately.
```

Then:

```text
/business-owner-oslo I run a small consulting business. I get calls but they stall after proposals. What should I fix first?
```

## Fallback: Individual Skill ZIPs

If the account does not show plugin upload, upload each ZIP from:

```text
dist/claude-skills/
```

This is not the preferred handoff path; it is here to avoid blocking setup.

## Expected Behavior

- Geoffrey acts as the main assistant operating loop.
- Geoffrey asks no more than three practical questions at once.
- Geoffrey does useful work before showing process.
- Geoffrey treats an existing assistant as the baseline to clear, not as the product vision.
- Geoffrey quietly tracks what it learns about workflows, access, preferences, and approval boundaries.
- Geoffrey uses a compact snapshot only when it helps the recipient feel less burdened.
- `business-owner-oslo` diagnoses business bottlenecks in Offers, Sales, Leads, Operations order when the request is business-growth specific.
- Claude does not expose internal worker mechanics unless asked.
- Claude does not treat reference material as source to copy.

## Handoff Acceptance Criteria

Geoffrey is ready for a recipient when:

1. The recipient can install Geoffrey or has someone install it once.
2. Geoffrey has completed one real useful task.
3. The recipient has accepted or corrected the output.
4. Geoffrey knows the highest-value current baseline workflows.
5. Required app, file, account, or automation access is documented when it blocks useful work.
6. Approval boundaries are clear enough to proceed safely.
7. The next easiest load-reducing task is identified.

## Project Map

```text
Geoffrey
├── CLAUDE.md
├── START_HERE.md
├── HANDOFF.md
├── .claude/skills/
├── plugins/geoffrey/
├── dist/Geoffrey-Claude-Plugin.zip
├── dist/claude-skills/
├── core/skills/
├── packs/
├── docs/
├── scripts/
└── reference/
```

## Source Boundary

`reference/` contains Optimus inventory captures and Web Agent Team reference material. Keep it out of redistributable Geoffrey source unless rights are reviewed.

The default handoff ZIP excludes `reference/` and includes only the usable Claude project files.

## Package Check

For local verification:

```bash
./scripts/check-claude-setup.sh
```

## Next Product Work

1. Smoke test `dist/Geoffrey-Claude-Plugin.zip` in Claude Desktop.
2. Run the Mauricio onboarding prompt.
3. Complete one real Viktor-baseline task that reduces Mauricio's load.
4. Capture only the access or approval gaps that blocked useful work.
5. Smoke test `/recipient-onboarding` and `/geoffrey` in Claude Code.
