# Geoffrey Architecture For Claude

## Runtime Shape

Geoffrey is organized as Claude project skills plus canonical Core and optional pack folders.

```text
Geoffrey
├── .claude/skills
│   ├── geoffrey
│   ├── execute-and-verify
│   ├── context-management
│   ├── authority-management
│   ├── geoffrey-onboarding
│   ├── business-owner-oslo
│   └── recipient-onboarding
├── plugins/geoffrey
│   ├── .claude-plugin/plugin.json
│   └── skills
├── core/skills
│   ├── geoffrey
│   ├── execute-and-verify
│   ├── context-management
│   ├── authority-management
│   └── geoffrey-onboarding
├── packs
│   ├── business-owner-oslo
│   └── recipient-onboarding
└── reference
    └── non-distributable research and inventory
```

## Core Loop

1. Understand the requested outcome.
2. Define what would prove completion.
3. Load Core skills and any relevant optional pack.
4. Check authority before consequential action.
5. Execute the smallest complete path.
6. Verify the actual result.
7. Repair failures when feasible.
8. Update durable context.
9. Report completion or blockers.

## Handoff Loop

When Geoffrey is handed to a new person:

1. Ask a few practical questions about what is on their plate.
2. Capture the current assistant or manual-work baseline through examples.
3. Pick one useful task that can reduce load now.
4. Do or draft that task.
5. Ask whether the output worked.
6. Quietly record preferences, access gaps, and approval boundaries.
7. Suggest the next easiest task, not a big plan.

## Workflow Loop

For repeatable workflows, Geoffrey should define:

- Input: request, event, trigger, file, message, or data.
- Transformation: model reasoning, skill instructions, tools, and standards.
- Output: delivered result and destination.
- Feedback: human review, metric, or correction that improves the next run.

If any part is vague, Geoffrey should tighten the workflow gradually through real use.

## Pack Loading

Claude Code discovers project skills from `.claude/skills/`. Core skills should be available in that folder. Packs should also be copied there when they are enabled for the project.

Examples:

- A recipient is receiving Geoffrey for the first time: load `recipient-onboarding`.
- Mauricio says he currently uses Viktor: load `recipient-onboarding` and treat Viktor as the baseline.
- A founder asks what to fix in their business this month: load `business-owner-oslo`.
- A user asks for a daily briefing: stay in Core unless a domain pack is needed.
- A user asks to build and deploy a website: later load `web-builder`.

## Source Boundary

Reference material can inform original Geoffrey design, but it is not source code for Geoffrey. Any pack derived from reference material must be rewritten into original workflows and reviewed before redistribution.
