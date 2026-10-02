# Geoffrey White-Glove Setup

Start here if you are giving Geoffrey to yourself or a friend:

- [START_HERE.md](START_HERE.md)
- [docs/friend-setup.md](docs/friend-setup.md)

Geoffrey is a Claude-compatible assistant system that turns natural-language
requests into completed, verified outcomes. The user interacts with one
assistant named Geoffrey; skills, tools, connectors, and temporary workers stay
behind the scenes unless the user asks.

This package is a friend-ready setup copy. It was copied from the Geoffrey source
repo and adds a white-glove setup path around it.

## Fastest Setup

On Mac, double-click:

```text
Install Geoffrey.command
```

Or use the terminal bootstrap. Have them open Terminal and paste:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/hammbino/Geoffrey_Installer/main/install.sh)"
```

If Geoffrey is already downloaded, run:

```bash
./bin/geoffrey setup
```

To see the first prompt:

```bash
./bin/geoffrey start
```

To see the first useful demo action:

```bash
./bin/geoffrey demo
```

To see setup status:

```bash
./bin/geoffrey status
```

To turn Geoffrey into the owner's chief of staff after memory is created:

```bash
./bin/geoffrey chief-of-staff --memory /path/to/geoffrey-memory-repo
```

To print the exact first-run prompt:

```bash
./bin/geoffrey first-run
```

To see the chief-of-staff tool inventory:

```bash
./bin/geoffrey apps
```

To view the broader connector playbook:

```bash
./bin/geoffrey connectors
```

To connect another email account later:

```bash
./bin/geoffrey add-email
```

To create Geoffrey's GitHub-backed memory and brain repo:

```bash
./bin/geoffrey memory --name "Your Name" --business "Your Business" --github your-github-name --push
```

## Product Frame

Geoffrey is not a clone of a previous assistant. For each new recipient, Geoffrey first reduces load, learns the current baseline through real work, then improves from there.

For Mauricio, that baseline is Viktor.

## Supported Paths

Geoffrey supports both:

- Claude Desktop: upload one plugin package from `dist/Geoffrey-Claude-Plugin.zip`.
- Claude Code: open the local project folder so Claude reads `CLAUDE.md` and `.claude/skills/`.
- Multi-account email/calendar: run `./bin/geoffrey setup`, then connect Gmail
  and Outlook accounts with short ids like `personal`, `work`, or `billing`.
  Public copies include Geoffrey's Gmail sign-in helper, so friends do not need
  to create a Google Cloud project.
- GitHub-backed memory: run `./bin/geoffrey memory` to create the private repo
  that holds `CLAUDE.md` and `memory/`. Friends do not need GitHub to download
  Geoffrey, but GitHub is part of onboarding because Geoffrey's memory lives in
  a private repo.
- Chief-of-staff tools: run `./bin/geoffrey chief-of-staff --memory PATH` to map
  the user's apps, plugin needs, operating rhythm, approval boundaries, and
  first custom Geoffrey skills.

For busy business users, Claude Desktop with the one-file plugin is the easiest path.

## Project Layout

- `START_HERE.md`: Desktop and Code setup instructions.
- `Install Geoffrey.command`: Mac double-click setup.
- `bin/geoffrey`: Terminal setup command.
- `docs/terminal-bootstrap.md`: Copy/paste terminal install and Claude Code check.
- `HANDOFF.md`: Handoff checklist and acceptance criteria.
- `CLAUDE.md`: Claude Code project memory.
- `docs/friend-setup.md`: Friend-ready setup instructions.
- `docs/friend-test-script.md`: Live test script for the first two friends.
- `docs/chief-of-staff-tools.md`: App/tool inventory and connection readiness.
- `docs/connector-playbook.md`: White-glove setup paths by tool category.
- `docs/first-use-demo.md`: Inbox Rescue and other first useful actions.
- `docs/github-memory-setup.md`: GitHub-backed memory setup.
- `docs/white-glove-walkthrough.md`: First-session questions and app discovery.
- `docs/multi-email-setup.md`: Geoffrey's multi-email setup.
- `.claude/skills/`: Claude Code project-skill mirror.
- `plugins/geoffrey/`: Claude plugin source that bundles Geoffrey skills.
- `dist/Geoffrey-Claude-Plugin.zip`: One-file Claude Desktop plugin package.
- `dist/claude-skills/`: Fallback Claude Desktop skill ZIPs, one per skill.
- `docs/handoff-packet-template.md`: Quiet recipient packet template.
- `docs/mauricio-onboarding-packet.md`: Mauricio starter packet with Viktor as the current baseline.
- `core/skills/`: Canonical user-agnostic Geoffrey Core skills.
- `packs/`: Canonical optional capability packs.
- `docs/`: Product specs, architecture notes, and Claude setup instructions.
- `scripts/`: Package validation helpers.
- `reference/`: Research and third-party reference material. This is not Geoffrey source.

## Core Skills

- `geoffrey`: Core operating behavior, routing, accountability, and reporting.
- `execute-and-verify`: Define done, execute, inspect, repair, and report evidence.
- `context-management`: Durable user, project, decision, and memory handling.
- `authority-management`: Approval and action-boundary rules.
- `geoffrey-onboarding`: Nontechnical first-run setup.

## Optional Packs

- `business-owner-oslo`: Diagnoses business bottlenecks across Offers, Sales, Leads, and Operations, then recommends one focused next move.
- `recipient-onboarding`: Gives a busy recipient a low-friction Geoffrey start: a few practical questions, one useful task, quiet baseline capture, access needs, approval rules, and next easiest wins.

## Package Check

```bash
./scripts/check-claude-setup.sh
```

## Reference Boundary

The `reference/` folder contains Optimus inventory notes, captured page summaries, and Web Agent Team reference material. Treat it as research material only. Geoffrey skills and packs must remain original rewrites, not copied source.
