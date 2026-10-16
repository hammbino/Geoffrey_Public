# Geoffrey GitHub Memory Setup

## What This Is

Geoffrey's memory and brain should live in a private GitHub repository for each
person.

That repo is simple:

- `CLAUDE.md` tells Geoffrey how to behave for the person.
- `memory/` stores durable context in Markdown.
- Git history records what Geoffrey learned and when.
- GitHub lets Geoffrey continue across machines, cloud sessions, and phones.

This is based on the `geoffrey-person-name` pattern.

## Fast Setup

From the Geoffrey folder:

```bash
./bin/geoffrey memory --name "Your Name" --business "Your Business"
```

Geoffrey will create a local memory repo at:

```text
~/Repos/geoffrey-your-name
```

To create the private GitHub repo at the same time:

```bash
./bin/geoffrey memory --name "Your Name" --business "Your Business" --github your-github-name --push
```

## GitHub CLI

The easiest path uses GitHub CLI.

Check whether it exists:

```bash
gh --version
```

If it is missing, install GitHub CLI, then run:

```bash
gh auth login
```

Choose:

- GitHub.com
- HTTPS
- Authenticate with browser

## What Geoffrey Creates

```text
geoffrey-your-name/
├── CLAUDE.md
├── README.md
└── memory/
    ├── README.md
    ├── user.md
    ├── projects/
    │   └── geoffrey.md
    ├── decisions/
    ├── people/
    ├── waiting/
    └── journal/
```

## First Prompt In The Memory Repo

Open the generated repo in Claude Code, Codex, or another coding assistant and
say:

```text
Read CLAUDE.md and onboard me with Geoffrey.
```

## Safety

Keep the GitHub repo private by default.

Do not store passwords, one-time codes, API keys, private tokens, card numbers,
or account recovery details in Geoffrey memory.

The Mac app's Memory screen is the supported sync surface. It distinguishes a
confirmed GitHub backup from a local-only save, an unreachable remote, and a
real two-sided conflict. Sync now fast-forwards remote-only changes and rebases
independent work. If the same content changed on both sides, Geoffrey aborts
the rebase and leaves the original local branch intact instead of choosing a
winner. The app records the last result locally in
`~/.geoffrey/memory-sync.json`; that operational status is not committed to the
memory repository.

Before an automatic commit, Geoffrey checks changed files for common credential
patterns and filenames, symbolic links, and files beyond its safe inspection
limit. A blocked file stays on the Mac and is not deleted, committed, or pushed.
