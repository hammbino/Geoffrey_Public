# Feedback Log

Record direct user feedback here. Keep it short and factual. Link each repeatable issue to a roadmap item or GitHub issue.

| Date | Person | What happened | What Geoffrey should do | Status |
| --- | --- | --- | --- | --- |
| 2026-10-19 | Geoffrey owner | Basic setup repeatedly failed despite passing checks; architecture felt too complex. Multiple email accounts are a defining feature. | Stabilize the actual setup journey, make backup optional, and preserve adding any number of Google/Microsoft accounts. | Local build 22 adds bundled runtimes, tested process execution, local-first memory, retryable backup, and Add another account. Packaged live acceptance remains pending. |
| 2026-10-19 | Geoffrey owner | Sidebar said “Ready to help” while Gmail needed repair. | Derive the sidebar message and color from account health and check failures as well as setup completion. | Corrected locally; regression tests cover completed setup with broken accounts, failed checks, and refresh in progress. Native build and isolated Mac checks pass; packaged live acceptance remains pending. |
| 2026-10-13 | Dustin | Terminal felt text-heavy and did not speak to him. | Make the Geoffrey Mac app the normal experience and reduce setup text. | Addressed in part; first-run wizard remains. |
| 2026-10-13 | Geoffrey owner | The setup added only one Gmail account and had no Back option. | Support multiple accounts plus Back, cancel, retry, switch-provider, and skip options. | Addressed in CLI; needs in-app flow. |
| 2026-10-13 | Geoffrey owner | Morning briefing content is not always useful. | Capture feedback and use it in future briefing prompts. | Implemented. |
| 2026-10-13 | Dustin | Needs to rate individual briefing priorities and add priorities Geoffrey missed. | Add priority rating and missed-priority learning to the Mac app and private memory. | Implemented; needs pilot validation. |
| 2026-10-13 | Geoffrey owner | New Mac app showed Continue setup before `~/Geoffrey` had been installed. | Detect a missing Geoffrey engine and launch the official installer instead. | Implemented; needs first-run validation. |
| 2026-10-13 | Geoffrey owner | “Short account id” was unclear while connecting an email account. | Ask for a private inbox label, explain that it does not change the address, and give examples. | Implemented; needs first-run validation. |
| 2026-10-13 | Geoffrey owner | Setup completed in Terminal rather than returning to the Geoffrey app. | Open Geoffrey immediately after email and private-memory setup; use Brief me for the first action. | Implemented; needs first-run validation. |
| 2026-10-13 | Geoffrey owner | “Person's name” was unclear during private-memory setup. | Ask what Geoffrey should call the owner, explain why, and give an example. | Implemented; needs first-run validation. |
| 2026-10-14 | Geoffrey owner | Brief me returned a generic error even though setup was ready. | Prepare a bounded read-only packet from private memory and connected account metadata, then ask Claude to reason from that packet without tool access. | Implemented and live-briefing validated. |
