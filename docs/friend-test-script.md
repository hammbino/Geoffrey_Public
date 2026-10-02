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
7. Run:

   ```bash
   ./bin/geoffrey status
   ```

8. Run:

   ```bash
   ./bin/geoffrey first-run
   ```

9. Open the generated memory repo in Claude/Codex and paste the first-run prompt.

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
6. Let Geoffrey continue into setup, connect email, ask whether they have GitHub,
   help them create/sign into GitHub if needed, and create the GitHub-backed
   memory repo.
7. Run Inbox Rescue as the first useful action.

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
./bin/geoffrey connectors
```

Then connect the rest of their core operating stack in stages.
