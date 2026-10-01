# Claude Setup

Geoffrey targets both Claude Desktop and Claude Code.

## Path A: Claude Desktop Plugin

Use this path for busy business users.

1. Open Claude Desktop and sign in.
2. Open Settings.
3. Enable Code execution and file creation.
4. Go to Customize > Plugins.
5. Choose the upload option.
6. Upload:

```text
dist/Geoffrey-Claude-Plugin.zip
```

The plugin contains the Geoffrey skill bundle:

```text
geoffrey/
├── .claude-plugin/plugin.json
└── skills/
    ├── geoffrey/SKILL.md
    ├── execute-and-verify/SKILL.md
    ├── context-management/SKILL.md
    ├── authority-management/SKILL.md
    ├── geoffrey-onboarding/SKILL.md
    ├── business-owner-oslo/SKILL.md
    └── recipient-onboarding/SKILL.md
```

After upload, open the installed Geoffrey plugin and make sure the skills are enabled.

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

## Desktop Fallback: Individual Skill Uploads

If plugin upload is not available, upload one skill ZIP at a time from:

```text
dist/claude-skills/
```

Each ZIP contains one top-level skill folder:

```text
recipient-onboarding.zip
└── recipient-onboarding/
    └── SKILL.md
```

This fallback is not the preferred handoff path.

## Path B: Claude Code

Use this path for local project work and technical testing.

Open the Geoffrey folder in Claude Code:

```bash
cd /path/to/Geoffrey
claude
```

Claude Code should automatically read:

- `CLAUDE.md`
- `.claude/skills/*/SKILL.md` metadata

Claude Code project skills can be invoked directly with slash commands:

- `/geoffrey`
- `/execute-and-verify`
- `/context-management`
- `/authority-management`
- `/geoffrey-onboarding`
- `/business-owner-oslo`
- `/recipient-onboarding`

Code test prompts:

```text
/recipient-onboarding I am handing Geoffrey to a busy business owner. Start with no more than three questions, then help with one useful task immediately.
```

```text
/business-owner-oslo I run a small consulting business. I get calls but they stall after proposals. What should I fix first?
```

## Project Structure

- `plugins/geoffrey/`: Claude plugin source.
- `dist/Geoffrey-Claude-Plugin.zip`: One-file Claude Desktop plugin package.
- `dist/claude-skills/`: Fallback Claude Desktop skill ZIPs.
- `.claude/skills/`: Claude Code project skills.
- `CLAUDE.md`: Claude Code project memory.
- `core/skills/`: Canonical Geoffrey Core skills.
- `packs/`: Canonical optional packs.
- `reference/`: Research and non-distributable reference material.
- `docs/`: Product and architecture notes.

## Validation Checklist

- The plugin has `.claude-plugin/plugin.json`.
- The plugin has all enabled skills under `skills/`.
- Every skill directory has `SKILL.md`.
- Every `SKILL.md` starts with YAML frontmatter.
- Every skill frontmatter has `name` and `description`.
- Every `name` matches its directory.
- No skill contains placeholder TODO text.
- Each fallback skill ZIP contains exactly one top-level skill folder.
- Claude Code project skills are mirrored under `.claude/skills/`.
- Reference material is not copied into distributable skills.
- Handoff readiness requires one real accepted useful task, not a setup packet or rollout plan.
