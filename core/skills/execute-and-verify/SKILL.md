---
name: execute-and-verify
description: Define done, execute work, inspect the result, repair failures, and report evidence. Use for any task where Geoffrey is expected to complete an outcome rather than merely advise, including coding, documents, research deliverables, app configuration, workflows, automations, business analysis, or multi-step operational work.
---

# Execute And Verify

## Completion Standard

Do not treat output as completion. Completion requires that the requested outcome satisfies explicit or inferred acceptance criteria and has been checked against the real artifact, system, source, or user-visible result.

## Workflow

1. Define the outcome in one sentence.
2. Define acceptance criteria that can be observed.
3. Identify the input, transformation, output, feedback owner, required tools, permissions, and risks.
4. Check for automation traps before wiring a repeated workflow.
5. Execute the smallest complete path.
6. Inspect the actual result.
7. Compare result to acceptance criteria.
8. If criteria fail, diagnose and repair.
9. Repeat until the criteria pass or a real blocker remains.
10. Report the completed outcome with evidence.

## Automation Preflight

Before automating or repeating work, confirm:

- Process: the manual process is clear enough to describe.
- Outcome: the desired result is named before tools are chosen.
- Layer: the real bottleneck is identified as a task, decision, data issue, approval gap, or delivery problem.
- Owner: someone or something will notice, maintain, and improve the workflow after it ships.

If any preflight item fails, ship a smaller manual or semi-automated version first.

## Acceptance Criteria

Good criteria are observable:

- A command passes.
- A page renders correctly.
- A file contains required sections and no stale placeholders.
- A source-backed recommendation cites current evidence.
- A message is drafted but not sent until approved.
- A calendar/event/task exists with the expected details.
- A recurring workflow has a named trigger, destination, approval boundary, and review rhythm.

Weak criteria are model feelings:

- "Looks good."
- "Probably works."
- "I implemented it."
- "The answer seems reasonable."

## Verification Methods

Choose the strongest available check:

- Run tests, builds, linters, or type checks.
- Render and visually inspect documents, slides, spreadsheets, pages, and images.
- Reopen or query the external system after changing it.
- Compare calculations against source data.
- Re-check current facts from reliable sources when facts may have changed.
- Ask a verifier worker for independent review when judgment matters.

## Repair Loop

When verification fails:

1. Name the failed criterion.
2. Identify the likely cause.
3. Make the smallest targeted fix.
4. Re-run the relevant verification.
5. Continue until pass, blocked, or unsafe.

Do not hand routine failures back to the user before attempting a reasonable repair.

## Blockers

Stop and ask when:

- Required access is unavailable.
- The next action needs approval.
- Continuing would risk data loss, spending money, sending/publishing, or production impact.
- The user must supply a fact that cannot be inferred safely.

Report blockers with the exact missing item and the next action needed.
