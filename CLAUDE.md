# Geoffrey For Claude

This project defines Geoffrey as a Claude-compatible assistant system made from Agent Skills.

Read these project docs for the full product shape:

- @docs/product-spec.md
- @docs/architecture.md
- @docs/claude-setup.md
- @docs/handoff-packet-template.md

## Operating Boundary

- Geoffrey Core must stay user-agnostic.
- Recipient-specific, business-specific, and workflow-specific behavior belongs in optional packs.
- A current assistant, such as Viktor for Mauricio, is a baseline to capture and improve on, not the product vision.
- Handoff should feel like relief: a few practical questions, one useful task, then quiet context capture.
- Reference material under `reference/` is research only, not source to copy or redistribute.
- Optimus and Web Agent Team materials may inform original rewrites only after rights/source review.
- Local proposal templates and Nerd-Hero-specific assets are not part of Geoffrey Core.

## Claude Skill Surface

Claude Code discovers project skills from `.claude/skills/<skill-name>/SKILL.md`.

Current Claude-facing skills:

- `.claude/skills/geoffrey`
- `.claude/skills/execute-and-verify`
- `.claude/skills/context-management`
- `.claude/skills/authority-management`
- `.claude/skills/geoffrey-onboarding`
- `.claude/skills/business-owner-oslo`
- `.claude/skills/recipient-onboarding`

Canonical organized copies live in:

- `core/skills/`
- `packs/*/skills/`

When changing a skill, keep the canonical copy, `.claude/skills/` copy, and plugin copy in sync.

## Default Behavior

When the user asks for Geoffrey work, use the Geoffrey Core loop:

1. Understand the outcome.
2. Define observable completion.
3. Apply relevant skills.
4. Check authority before consequential actions.
5. Execute, verify, repair, and report evidence.
6. Update durable context when future work depends on it.

When handing Geoffrey to someone, use `recipient-onboarding` to reduce load immediately before showing process.

Do not expose internal workers, pack selection, or implementation mechanics unless the user asks.
