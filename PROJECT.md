# Geoffrey OS Project Notes

This is the working and shipping repository for Geoffrey: the Mac assistant that helps an individual run their day, connect their tools, remember what matters, and improve over time.

## Where Things Live

| What | Location |
| --- | --- |
| Geoffrey source, Mac app, tests, and distributions | This repository |
| Mac app source | `GeoffreyMac/` |
| Embedded Geoffrey engine | `geoffrey-mcp/` |
| Release scripts and verification | `scripts/` |
| Claude skills and plugin packages | `.claude/`, `plugins/`, and `dist/` |
| Product and release record | `docs/` |

## The Goal

A person with little technical experience should be able to install Geoffrey, preserve or connect the accounts and capabilities they use, and get real value from Claude without needing to understand Git, OAuth, Claude Code, MCP servers, or a terminal.

## Start Here

- [Current product status](docs/CURRENT-STATUS.md)
- [Desktop release record and Dustin gate](docs/DESKTOP-RELEASE.md)
- [Friend test plan](docs/FRIEND-TEST.md)
- [Onboarding experience](docs/ONBOARDING.md)
- [Product decisions](docs/DECISIONS.md)
- [Build roadmap](docs/ROADMAP.md)
- [Feedback log](docs/FEEDBACK.md)

## Working Agreement

1. Geoffrey is the product name everywhere.
2. Daily use should happen in the Geoffrey Mac app, not in Terminal.
3. Never commit OAuth secrets, credentials, tokens, or a person's private memory.
4. Preserve existing user state before replacing any part of the legacy installation.
5. Keep credentials, tokens, private memory, and real recipient data out of Git and release packages.
6. A change is not complete until its relevant automated checks pass and its user-facing behavior is inspected.
7. A branch push is not a release; Dustin receives an update only after the documented release gate passes.
