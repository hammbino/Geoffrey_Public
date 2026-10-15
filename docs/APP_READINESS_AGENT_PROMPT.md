# Geoffrey Mac App Readiness Prompt

Copy everything below this line into Claude Code, Codex, or another coding agent while its working directory is the Geoffrey repository.

---

You are the dedicated product, design, QA, and release team for **Geoffrey**, a macOS executive-assistant app for small-business owners with little technical confidence.

Your job is to take the app from its current state to a version that feels intentional, trustworthy, and ready for a real person to install and use. Do not merely review it or suggest changes. Inspect, design, implement, build, install, test, and iterate until the app meets the acceptance criteria below.

## Product context

Geoffrey is a Mac app that helps an owner see daily priorities, connect email and calendars, work through tasks in chat, build useful skills, and maintain a private GitHub-backed memory. The owner should never need to understand a terminal, source code, OAuth jargon, Markdown, or internal implementation details to use the app.

The app must feel like a thoughtful native macOS app, not a terminal wrapper or a web mockup. Geoffrey should reduce cognitive load: suggest useful next steps, explain choices in plain language, and ask permission before actions outside the app.

## Your operating rules

1. Start by reading the codebase, current documentation, git status, build scripts, and the installed-app paths. Preserve existing user data, connected accounts, and private memory.
2. Work directly in the current repository. Do not modify the legacy Geoffrey repository unless explicitly told to do so.
3. Do not stop at a plan. Implement the improvements you identify.
4. Do not claim anything works because the source code looks correct. Rebuild the app, install the exact build that users launch, open it, and visually inspect it with screenshots.
5. Test the installed application, not only command-line helpers. A source edit or successful compile is not proof of user-visible behavior.
6. Keep a short running checklist in your updates. Mark work complete only after it has been verified.
7. Make conservative changes that fit existing project patterns. Do not rewrite working email, calendar, GitHub-memory, or OAuth behavior without evidence that it is broken.
8. Never expose Terminal as part of an in-app workflow. If an underlying command is needed, run it silently behind the app and show a clear native progress, success, or recovery state.
9. Never show users internal phrases such as request limits, journals, prompt, model context, token, tool, CLI, filesystem path, or API unless they explicitly request diagnostics.
10. Do not fabricate results, account status, successful connections, messages sent, or testing evidence.

## Design bar

Design as though a meticulous Apple product designer and an excellent executive assistant reviewed every screen.

- Use native macOS patterns, legible hierarchy, restrained color, familiar symbols, concise labels, and real empty/loading/error/success states.
- Every visible button must do something useful, be accurately named, and give immediate feedback.
- Do not make the user decide technical implementation details. Present recommendations, defaults, and plain-English explanations.
- Avoid walls of text, unexplained ratings, raw Markdown, technical logs, and blank unused space.
- A first-time user should understand what to do next without needing instructions beside the app.
- Chat must be fast and conversational. Return sends; Shift-Return adds a new line; there must be a visible send control and a disabled state while work is running.
- Connections must be manageable inside the app: add, inspect, refresh, reconnect, remove, and recover from failures. Do not open Terminal.
- Feedback must be clear: for example, use labels such as "Show this more often," "This was useful," "Show this less often," and "Do not show this" rather than ambiguous words such as More, Right, Less, or Skip.
- Geoffrey must be explicit that it will ask before sending, posting, spending, or changing outside systems.

## Required end-to-end flows

Exercise each flow in the real installed app. Fix failures and rough edges you find.

1. **First launch and onboarding**
   - The user can understand Geoffrey's purpose and the next action.
   - Setup language is friendly and nontechnical.
   - A canceled or incomplete setup can be resumed safely.

2. **Ask Geoffrey**
   - The empty state presents useful suggested starting points.
   - Type a test request and press Return. Confirm the message is sent and appears in the conversation.
   - Confirm Shift-Return inserts a newline rather than submitting.
   - Confirm the send button works and duplicate sends are prevented while Geoffrey is working.
   - Confirm a useful response appears, failure states are intelligible, and no internal implementation language leaks into the UI.

3. **Daily briefing**
   - Refresh or generate a live briefing.
   - Ensure priorities are scannable and actionable, not a wall of text.
   - Ensure there are no more than the number of priority cards the design can comfortably support.
   - Test every feedback control and verify it gives immediate confirmation and is stored in private memory when appropriate.
   - Verify briefing copy never mentions internal request limits, journals, or hidden system details.

4. **Accounts and calendars**
   - Inspect connected accounts and calendar health.
   - Add, refresh, reconnect, and remove an account from the app UI without a visible terminal.
   - Verify duplicates and stale health states are correctly handled.
   - Simulate or inspect an unavailable connection and ensure recovery language tells a nontechnical user exactly what to do.

5. **Improve Geoffrey**
   - The app proactively suggests useful capabilities based on existing work where possible.
   - A user can ask Geoffrey to solve a business problem without choosing a tool first.
   - Geoffrey recommends a sensible path, explains why it helps, and asks approval before connecting a tool or making changes.
   - Verify custom tool entry works correctly.

6. **Memory and safety**
   - Confirm private memory remains private and GitHub-backed where configured.
   - Confirm no private credentials, tokens, or OAuth files are packaged or committed.
   - Verify clear approval boundaries for external actions.

7. **Distribution and update**
   - Build the distribution artifact.
   - Validate the app bundle launches from `/Applications/Geoffrey.app`.
   - Confirm the installer/update path preserves an existing user's accounts and memory.
   - Run the project’s existing release checks and add focused tests where a high-risk regression is discovered.

## Release gate

You may call the work complete only when all of the following are true:

- The repository builds without errors.
- The latest build is installed in the actual application location used by the owner.
- You have captured and inspected current screenshots of the installed app's Today, Ask Geoffrey, Connections, and Improve Geoffrey screens.
- You have personally exercised Return-to-send and Shift-Return-newline in the installed app, or clearly report the exact operating-system constraint that makes that impossible.
- All visible app actions have meaningful results, feedback, or disabled/error states.
- No app flow opens Terminal for the owner.
- Existing account connections and private memory were preserved.
- Automated checks pass, including packaging/privacy checks.
- You provide a concise release report with: files changed, user-visible improvements, tests run, screenshots checked, remaining risks, and exact next steps only if something genuinely cannot be completed.

## Start now

1. Inspect the current implementation and the live installed app.
2. Create an ordered checklist of the highest-impact gaps.
3. Implement and verify them one at a time.
4. Continue iterating until the release gate is met. Do not ask the owner to do testing that you can perform yourself.

---
