# Geoffrey Connector Playbook

## Purpose

Geoffrey should be able to help a small business owner set up the tools they
actually use, not only email.

The setup should feel like:

1. Tell Geoffrey what apps run the business.
2. Geoffrey marks what is ready, what needs sign-in, and what should wait.
3. Geoffrey walks through the important connections one by one.
4. Geoffrey proves usefulness with a real action.
5. Geoffrey keeps walking through the remaining core tools the person actually
   uses.

## Core Setup Stack

### 1. Memory And GitHub

What it is: Geoffrey's private notebook and brain.

Command:

```bash
./bin/geoffrey memory --name "Name" --business "Business" --github username --push
```

Why it matters: Geoffrey can remember across devices and future sessions.

### 2. Email And Calendar

What it is: Gmail, Outlook, Microsoft 365, Google Calendar, Outlook Calendar.

Command:

```bash
./bin/geoffrey add-email
```

Gmail uses Geoffrey's bundled OAuth app. The user clicks through Google's
unverified-app warning.

Outlook/Microsoft 365 is built through Microsoft Graph. If
`geoffrey-mcp/config/microsoft-oauth.json` exists, the user just signs in. If
not, use `docs/outlook-setup.md`.

First wins:

- Inbox Rescue.
- Today's Schedule.
- Client Follow-Up Finder.

### 3. Files And Documents

Common tools:

- Google Drive
- OneDrive
- SharePoint
- Dropbox
- Box
- Local folders
- Google Docs, Sheets, Slides
- Microsoft Word, Excel, PowerPoint

Connection paths:

- Native ChatGPT/Codex connector when available.
- Browser sign-in when connector is not available.
- Local folder selection for files on the computer.
- Upload/export for one-time help.

First wins:

- Find key documents.
- Summarize proposals or contracts.
- Build a document/template library.

### 4. Tasks And Projects

Common tools:

- Asana
- ClickUp
- Trello
- Linear
- Jira
- Monday
- Todoist
- Apple Reminders

First wins:

- Open Loops List.
- Weekly priority review.
- Project status summary.

### 5. CRM And Clients

Common tools:

- HubSpot
- Salesforce
- Airtable
- Pipedrive
- GoHighLevel

First wins:

- Find stalled deals.
- Draft client follow-ups.
- Prep for sales calls.
- Build a pipeline review.

### 6. Money And Billing

Common tools:

- Stripe
- QuickBooks
- Xero
- Square
- PayPal
- Wave

First wins:

- Overdue invoice review.
- Payment and subscription questions.
- Billing follow-up drafts.

### 7. Chat And Meetings

Common tools:

- Slack
- Teams
- iMessage exports
- WhatsApp exports
- Otter
- Read AI
- Granola

First wins:

- Pull action items.
- Draft meeting follow-ups.
- Prepare for upcoming meetings.

### 8. Website, Marketing, Socials, And Analytics

Common tools:

- WordPress
- Webflow
- Wix
- Squarespace
- Shopify
- Framer
- Vercel
- LinkedIn
- Facebook
- Instagram
- TikTok
- YouTube
- X / Twitter
- Threads
- Google Business Profile
- Mailchimp
- ConvertKit
- beehiiv
- Google Analytics
- Google Search Console

First wins:

- Content calendar.
- Social post drafts.
- Review response drafts.
- Site update plan.
- Campaign/report summary.
- Follow-up list from forms/leads.

## Readiness Labels

- Ready now: Geoffrey can help from current context or pasted/exported data.
- Needs sign-in: user must authenticate in the app/browser/connector.
- Needs example: Geoffrey needs one real sample before automating.
- Needs setup: connector, repo, API key, or workflow must be created.
- Too risky for now: delay until boundaries are clearer.

## Approval Rules

Geoffrey may read, summarize, organize, and draft.

Geoffrey must ask before:

- Sending messages.
- Publishing content.
- Spending money.
- Deleting data.
- Deploying sites or changing DNS.
- Updating customer records.
- Creating recurring automations.
