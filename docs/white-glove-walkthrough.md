# Geoffrey White-Glove Walkthrough

## Goal

Geoffrey should feel easy enough to hand to a friend.

The first session should not make the recipient learn agents, skills, MCP,
OAuth, or folders. Geoffrey should ask a few practical questions, learn where
the person's work lives, connect only the accounts needed for first value, and
take one useful task off their plate.

## First Prompt

Paste this into Claude, Codex, or ChatGPT with the generated Geoffrey memory
repo open. If the memory repo has not been created yet, use the Geoffrey setup
folder.

```text
Use Geoffrey.

Onboard me with a white-glove setup.

Ask me no more than three questions at a time. First learn what I do, what is on
my plate, what applications I use, and which email/calendar accounts I want
Geoffrey to see. Then take one useful task off my plate before showing me any
detailed system map.
```

## First Three Questions

1. What do you do, and what kind of work do you wish Geoffrey would take off
   your plate first?
2. What is one real thing on your plate today that you would love not to carry?
3. Which applications hold your work right now?

## App Discovery

Ask these only as relevant. Do not dump the whole list unless the user asks.

| Area | Examples |
|---|---|
| Email | Gmail, Outlook, Microsoft 365, Apple Mail |
| Calendar | Google Calendar, Outlook, Apple Calendar, Calendly |
| Chat | Slack, Teams, iMessage, WhatsApp, Discord |
| Files/docs | Google Drive, OneDrive, Dropbox, Box, Notion, Confluence |
| Projects/tasks | Asana, ClickUp, Trello, Linear, Jira, Monday, Todoist, Reminders |
| CRM/customers | HubSpot, Salesforce, Airtable, Pipedrive, GoHighLevel |
| Money | Stripe, QuickBooks, Xero, Square, PayPal, Wave |
| Website/content | WordPress, Webflow, Wix, Squarespace, Shopify, Framer, Vercel |
| Marketing/socials | LinkedIn, Facebook, Instagram, TikTok, YouTube, X/Twitter, Threads, Google Business Profile, Mailchimp, ConvertKit, beehiiv |
| AI/automation | ChatGPT, Claude, Zapier, Make, n8n, Shortcuts, custom code |

Use `docs/chief-of-staff-tools.md` for the full tool inventory and readiness
labels.

## Readiness Labels

- Ready now: Geoffrey can help without extra access.
- Needs access: the user must connect or sign in.
- Needs example: Geoffrey needs one real sample.
- Needs build: the workflow does not exist yet.
- Too risky for now: delay until authority boundaries are clearer.

## Multi-Email Setup

Geoffrey solves Claude's one-email limitation through `geoffrey-mcp`, a local
connector that can hold many Gmail and Outlook accounts. Each mailbox gets an id
like `personal`, `work`, `billing`, or `sales`.

Important:

- Geoffrey must always call `list_accounts` first.
- Every email/calendar action must name the account id.
- Geoffrey can create drafts, but it does not send email.
- Calendar access is read-only by default.

Setup command:

```bash
./bin/geoffrey setup
```

Add another mailbox later:

```bash
./bin/geoffrey add-email
```

Geoffrey will keep offering to add another mailbox until the user says no. If
they make a mistake during email setup, type `back`; to stop, type `cancel`.

## GitHub Memory Setup

Geoffrey's memory and brain live in a private GitHub-backed repo.

Setup command:

```bash
./bin/geoffrey memory --name "Your Name" --business "Your Business" --github your-github-name --push
```

This creates:

- `CLAUDE.md` for Geoffrey's operating brain.
- `memory/user.md` for stable user context.
- `memory/projects/` for live work.
- `memory/decisions/` for durable decisions.
- `memory/people/` for important contacts.
- `memory/waiting/` for follow-ups.
- `memory/journal/` for working notes.

The repository should be private by default.

## First Useful Task Menu

Pick one real low-risk task. Default to Inbox Rescue if email is connected:

- Draft a follow-up email, but do not send it.
- Turn meeting notes into actions.
- Summarize a messy idea into a plan.
- Review open loops.
- Create a project file.
- Prepare today's briefing.

Use `docs/first-use-demo.md` for the exact prompts.

## First Session Close

End with:

- What Geoffrey completed.
- What Geoffrey learned about the person.
- Which apps/accounts matter first.
- What access or examples are still needed.
- The next easiest thing Geoffrey can take off their plate.
