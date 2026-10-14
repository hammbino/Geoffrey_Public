# Geoffrey OS Project Notes

This is the working home for Geoffrey: the Mac assistant that helps a small-business owner run their day, connect their tools, remember what matters, and improve over time.

It is intentionally separate from the repositories that ship Geoffrey. This folder holds the decisions, test notes, friend onboarding, and roadmap that make the product easier to improve without losing the thread.

## Where Things Live

| What | Location |
| --- | --- |
| Public Geoffrey app and friend-ready distribution | `/Users/jeffrey/Repos/Geoffrey_Public` |
| White-glove handoff copy and release zip | `/Users/jeffrey/Repos/Geoffrey-WhiteGlove` |
| One-command installer | `/Users/jeffrey/Repos/Geoffrey_Installer` |
| Original Geoffrey project | `/Users/jeffrey/Repos/Geoffrey` (reference only; do not edit) |

## The Goal

A friend with little technical experience should be able to install Geoffrey, connect the accounts they use, and get real value from a first daily briefing without needing to understand Git, OAuth, Claude Code, or a terminal.

## Start Here

- [Current product status](docs/CURRENT-STATUS.md)
- [Friend test plan](docs/FRIEND-TEST.md)
- [Onboarding experience](docs/ONBOARDING.md)
- [Product decisions](docs/DECISIONS.md)
- [Build roadmap](docs/ROADMAP.md)
- [Feedback log](docs/FEEDBACK.md)

## Working Agreement

1. Geoffrey is the product name everywhere.
2. Daily use should happen in the Geoffrey Mac app, not in Terminal.
3. Never commit OAuth secrets, credentials, tokens, or a person's private memory.
4. Keep the public repo and the white-glove copy in sync for friend-facing changes.
5. A change is not complete until a first-time-user path has been considered and documented.
