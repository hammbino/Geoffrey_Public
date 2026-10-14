# Geoffrey App

Geoffrey.app is the everyday Mac workspace for a business owner. The command
line remains Geoffrey's installation and support engine; the owner should not
need to use it for normal work.

## What The Owner Sees

- **Today**: a daily briefing plus Inbox Rescue, Follow-ups, and Open Loops.
- **Ask Geoffrey**: one plain-language request box.
- **Improve Geoffrey**: a capability review that recommends the next useful
  skill, tool connection, or improvement, plus an approved private-skill
  builder for recurring business work.
- **Connections**: a simple view of email/calendar, private memory, and GitHub
  backup readiness.
- **Memory**: the private folder where Geoffrey keeps agreed context and
  briefing feedback.

Geoffrey never sends, publishes, spends, deletes, changes access, or creates
recurring automation without asking first.

## Adding Another Email Or Calendar

Choose **Accounts > Add email or calendar account** from Geoffrey's Mac menu at
any time. Geoffrey supports more than one Gmail and/or Microsoft account. If a
sign-in fails, the guided flow offers Retry, the other provider, or Skip so the
owner can move on to another account without starting setup over.

If a previously connected mailbox needs fresh permission, use the same menu
item and reconnect it with the same short account name.

If Geoffrey says the Claude sign-in needs refreshing, choose **Accounts > Sign
in to Claude** from the same menu.

## Skills And Business Tools

In **Improve Geoffrey**, the owner can ask Geoffrey to review their current
work and recommend no more than three improvements. Each recommendation states
its type, why it matters now, the first useful result, and the smallest access
or approval needed.

The owner can also describe repeated work and choose **Create private skill**.
Geoffrey creates a concise, owner-specific skill in `memory/skills/` with its
own approval boundary. Skill creation can update only the private skill and the
chief-of-staff map. It cannot connect accounts, send messages, publish, spend,
or modify outside tools.

Outside plugins and business-tool connections always require the owner's
approval and sign-in. Geoffrey recommends the smallest useful connection before
opening that setup path.

## Choosing A Claude Model

Open **Settings** and choose how Geoffrey should think:

- **Automatic**: Claude Code chooses the best available model. This is the
  default and best choice for most people.
- **Faster**: use Sonnet for routine daily work and quicker responses.
- **Deep thinking**: use Opus for complex planning, analysis, and skill design.
- **Custom**: enter a model name supplied by an organization or Claude account.

The selected model is used for briefings, Ask Geoffrey, capability reviews, and
private-skill creation. The same choices are also available from Geoffrey's
**Model** menu.

## Feedback That Improves The Briefing

After a daily briefing, the owner can choose **Helpful** or **Adjust it**.
"Adjust it" offers common corrections such as shorter briefings, less routine
email, more calendar/priorities, or more follow-ups, plus a free-text note.

Each response is saved in the private memory repo at
`memory/briefing-feedback.md`. Geoffrey reads that feedback on later briefings
and should confirm a correction before promoting it into the owner's standing
preferences.

## Install And Update

The normal Geoffrey installer builds Geoffrey.app locally and installs it in
`~/Applications/Geoffrey.app`. A local build avoids distributing an unsigned
application and keeps the app matched to the installed Geoffrey engine.

To repair or rebuild it:

```bash
cd ~/Geoffrey && ./bin/geoffrey install-mac-app
```

Geoffrey rebuilds the app as part of a normal Geoffrey update.
