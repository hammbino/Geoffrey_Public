# Friend Test Script

Use this when giving Geoffrey to the first two friends. Stay with them on Zoom
or in person.

## Goal

The friend should reach a useful result in the first 20 minutes.

Success looks like:

1. They run the installer or terminal bootstrap.
2. They connect at least one mailbox.
3. They create Geoffrey memory.
4. Geoffrey runs Inbox Rescue or Today's Schedule.
5. Geoffrey drafts something useful without sending it.

## Script A: Zip Installer

1. Send them the Geoffrey zip.
2. Ask them to unzip it.
3. Ask them to double-click `Install Geoffrey.command`.
4. When Gmail opens, tell them:

   ```text
   Google will warn that Geoffrey is not verified. That is expected because this
   is a private friends-and-family tool. Click Advanced, then continue.
   ```

5. If they use Outlook and Microsoft is not bundled yet, skip Outlook unless
   they are comfortable with the setup.
6. Let Geoffrey create the memory repo.
7. Confirm **Geoffrey** appears in Applications and open it.
8. Choose **Brief me** or **Inbox** inside Geoffrey.
9. Ask them whether the result was useful. If not, choose **Adjust it** and
   save one correction.
10. Run:

   ```bash
   ./bin/geoffrey dashboard
   ```

11. The old `Geoffrey.command` button remains available as a support fallback.
    The friend should normally use Geoffrey.app.
12. If needed, run:

   ```bash
   ./bin/geoffrey first-win
   ```

13. Pick Daily Briefing or Inbox Rescue and let Geoffrey produce the first useful result.

## Script B: Terminal Bootstrap

Use this if they are comfortable opening Terminal and pasting one block.

1. Ask them to open Terminal.
2. Have them paste:

   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/hammbino/Geoffrey_Installer/main/install.sh)"
   ```

3. The public installer should download Geoffrey without a GitHub account.
4. Geoffrey should check Homebrew, Node/npm, Claude Code, and email setup.
5. If Homebrew, Node.js, or Claude Code is missing, the flow should offer to install it.
6. Let Geoffrey continue into setup, connect every email/calendar account they
   want, ask whether they have GitHub,
   help them create/sign into GitHub if needed, and create the GitHub-backed
   memory repo.
7. Confirm Geoffrey appears in Applications and open it.
8. Let the friend choose **Brief me** or **Inbox** in Geoffrey as the first useful action.
9. Ask for one piece of feedback, then use **Helpful** or **Adjust it** to save it.

## Watch For Confusion

Write down every moment where they ask:

- What is this?
- Which option do I pick?
- Is this safe?
- Did it work?
- What do I do next?

Those are setup bugs.

## After The First Win

Run:

```bash
./bin/geoffrey tools --memory /path/to/their/geoffrey-memory-repo
./bin/geoffrey chief-of-staff --memory /path/to/geoffrey-memory-repo
```

Then connect the rest of their core operating stack in stages.

Use:

```bash
./bin/geoffrey connect-tool --memory /path/to/geoffrey-memory-repo
```
