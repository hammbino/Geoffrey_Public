# Microsoft Fresh Start

Use this when the Microsoft account you started with is the wrong one, the
portal got confusing, or you simply want a clean owner account for Geoffrey.

The cleanest setup is:

- A dedicated Microsoft/Azure account owns the Geoffrey app registration.
- Friends still sign in with their own Outlook or Microsoft 365 mailbox later.
- Geoffrey stores only the public Application Client ID, not a Microsoft
  password or secret.

## What you can skip

If you never created `geoffrey-mcp/config/microsoft-oauth.json`, there is
nothing to clean up on your Mac. Geoffrey has not saved the Microsoft app yet.

## Clean up the old attempt

1. Sign in to <https://entra.microsoft.com> with the old Microsoft account.
2. Go to **Identity -> Applications -> App registrations**.
3. Change the filter to **All applications** if needed.
4. Open any app named **Geoffrey** that you created by mistake.
5. Choose **Delete**.
6. Sign out of Microsoft in that browser.

If the portal will not let you sign in with that old account, you can skip this.
An unfinished registration is not connected to Geoffrey yet.

## Create the new free Microsoft owner account

1. Create or choose the Microsoft account you want to use as Geoffrey's owner.
2. Go to <https://azure.microsoft.com/free> and create a free Azure account if
   Microsoft asks for one.
3. Go to <https://entra.microsoft.com>.
4. Open **Identity -> Overview**.
5. If Microsoft asks you to create a tenant, choose **Microsoft Entra ID**.

Use simple values:

| Field | Value |
|---|---|
| Organization name | `Geoffrey` |
| Initial domain | `geoffrey-yourname` or similar |
| Country/region | Your country |

Do not choose External ID or B2C for this Geoffrey setup.

## Register the Geoffrey app

1. In Entra, go to **Identity -> Applications -> App registrations**.
2. Click **New registration**.
3. Name it `Geoffrey`.
4. For supported accounts, choose:

   **Accounts in any organizational directory and personal Microsoft accounts**

5. For Redirect URI, choose:

   **Public client/native (mobile & desktop)**

6. Enter exactly:

   ```text
   http://localhost:8731
   ```

7. Click **Register**.

## Finish the app settings

1. Copy the **Application (client) ID** from the Overview page.
2. Go to **Authentication**.
3. Confirm `http://localhost:8731` is under **Mobile and desktop applications**.
4. Near the bottom, set **Allow public client flows** to **Yes** if the toggle is
   shown.
5. Click **Save**.

## Add Graph permissions

Go to **API permissions -> Add a permission -> Microsoft Graph -> Delegated
permissions**, then add:

- `User.Read`
- `Mail.ReadWrite`
- `Calendars.Read`
- `offline_access`

Do not add `Mail.Send` for the starter setup. Geoffrey should draft first, not
send mail automatically.

## Save it into Geoffrey

Create `geoffrey-mcp/config/microsoft-oauth.json` with this shape:

```json
{
  "client_id": "paste-the-application-client-id-here"
}
```

Then rebuild the shareable Geoffrey zip.

