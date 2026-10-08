# Geoffrey App

Geoffrey.app is the everyday Mac workspace for a business owner. The command
line remains Geoffrey's installation and support engine; the owner should not
need to use it for normal work.

## What The Owner Sees

- **Today**: a daily briefing plus Inbox Rescue, Follow-ups, and Open Loops.
- **Ask Geoffrey**: one plain-language request box.
- **Connections**: a simple view of email/calendar, private memory, and GitHub
  backup readiness.
- **Memory**: the private folder where Geoffrey keeps agreed context and
  briefing feedback.

Geoffrey never sends, publishes, spends, deletes, changes access, or creates
recurring automation without asking first.

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
