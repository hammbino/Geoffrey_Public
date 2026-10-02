# Private Gmail Setup Code

Geoffrey's public package includes `geoffrey-mcp/config/google-oauth.enc.json`.
That file is encrypted so the raw Google OAuth file is not published to GitHub.

The setup code is stored only on Jeffrey's computer:

```text
~/.geoffrey/geoffrey-gmail-setup-code.txt
```

When a friend connects Gmail, Geoffrey may ask:

```text
Geoffrey Gmail setup code:
```

Give them the code from that local file. They paste it once, Geoffrey decrypts
the Gmail helper locally, then Google opens in the browser. The Google
unverified-app warning is expected for this private friends-and-family tool.

Do not commit the raw `geoffrey-mcp/config/google-oauth.json` file to any public
repo.
