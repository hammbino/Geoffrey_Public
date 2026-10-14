#!/usr/bin/env node
// Connect a mailbox to Geoffrey.
//
// Google:
//   npm run add-account -- --secrets ~/Downloads/client_secret_XXX.json --id work
//
// Microsoft:
//   npm run add-account -- --provider microsoft --id outlook

import { createServer } from "node:http";
import { createHash, randomBytes } from "node:crypto";
import { existsSync, readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { createInterface } from "node:readline/promises";
import { exec } from "node:child_process";
import { fileURLToPath } from "node:url";
import { upsertAccount, storePath } from "../src/store.js";

const PORT = 8731;
const HERE = dirname(fileURLToPath(import.meta.url));
const DEFAULT_GOOGLE_OAUTH = join(HERE, "../config/google-oauth.json");
const DEFAULT_MICROSOFT_OAUTH = join(HERE, "../config/microsoft-oauth.json");

const PROVIDERS = {
  google: {
    auth: "https://accounts.google.com/o/oauth2/v2/auth",
    token: "https://oauth2.googleapis.com/token",
    scope: [
      "https://www.googleapis.com/auth/gmail.modify",
      // Read-only on purpose: creating an event with attendees sends real
      // invitations, which belongs behind the same gate as sending mail.
      "https://www.googleapis.com/auth/calendar.readonly",
    ].join(" "),
    redirect: `http://127.0.0.1:${PORT}`,
    confidential: true,
    async identify(token) {
      const r = await fetch("https://gmail.googleapis.com/gmail/v1/users/me/profile", {
        headers: { Authorization: `Bearer ${token}` },
      });
      if (!r.ok) throw new Error(`Gmail rejected the token (${r.status}): ${await r.text()}`);
      const p = await r.json();
      return { email: p.emailAddress, detail: `${p.messagesTotal} messages` };
    },
  },
  microsoft: {
    // "common" accepts personal Outlook.com and work/school accounts alike.
    auth: "https://login.microsoftonline.com/common/oauth2/v2.0/authorize",
    token: "https://login.microsoftonline.com/common/oauth2/v2.0/token",
    scope: "Mail.ReadWrite Calendars.Read User.Read offline_access",
    // Entra matches redirect URIs exactly. Register this string verbatim.
    redirect: `http://localhost:${PORT}`,
    confidential: false, // public client: PKCE, no secret
    async identify(token) {
      const r = await fetch("https://graph.microsoft.com/v1.0/me", {
        headers: { Authorization: `Bearer ${token}` },
      });
      if (!r.ok) throw new Error(`Graph rejected the token (${r.status}): ${await r.text()}`);
      const p = await r.json();
      return { email: p.mail ?? p.userPrincipalName, detail: p.displayName ?? "" };
    },
  },
};

const arg = (name) => {
  const i = process.argv.indexOf(`--${name}`);
  return i > -1 ? process.argv[i + 1] : undefined;
};

const b64url = (buf) =>
  buf.toString("base64").replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");

async function ask(q) {
  const rl = createInterface({ input: process.stdin, output: process.stdout });
  const a = await rl.question(q);
  rl.close();
  return a.trim();
}

function waitForCode(expectedState, redirect) {
  return new Promise((resolve, reject) => {
    let timer;
    const finish = (fn, value) => {
      clearTimeout(timer);
      fn(value);
    };
    const server = createServer((req, res) => {
      const url = new URL(req.url, redirect);
      const code = url.searchParams.get("code");
      res.writeHead(200, { "Content-Type": "text/html; charset=utf-8" });
      res.end(code
        ? "<h2>Connected.</h2><p>Close this tab and return to the terminal.</p>"
        : `<h2>Authorization failed.</h2><pre>${url.search}</pre>`);
      server.close();
      if (!code) return finish(reject, new Error(`No authorization code: ${url.search}`));
      if (url.searchParams.get("state") !== expectedState) {
        return finish(reject, new Error("State mismatch — aborting."));
      }
      finish(resolve, code);
    });
    server.listen(PORT, "127.0.0.1");
    timer = setTimeout(() => {
      server.close();
      reject(new Error("Timed out waiting for consent."));
    }, 300_000);
  });
}

// --- resolve provider + credentials ------------------------------------------

const providerName = arg("provider") ?? "google";
const cfg = PROVIDERS[providerName];
if (!cfg) {
  console.error(`Unknown provider "${providerName}". Use: ${Object.keys(PROVIDERS).join(", ")}`);
  process.exit(1);
}

let client_id;
let client_secret;

if (providerName === "google") {
  const secretsPath = arg("secrets") ?? (existsSync(DEFAULT_GOOGLE_OAUTH) ? DEFAULT_GOOGLE_OAUTH : undefined);
  if (!secretsPath) {
    console.error(
      "Missing Google OAuth configuration.\n" +
      "Expected bundled config at geoffrey-mcp/config/google-oauth.json, or pass --secrets <path to client_secret_*.json>."
    );
    process.exit(1);
  }
  const raw = JSON.parse(readFileSync(secretsPath.replace(/^~/, process.env.HOME), "utf8"));

  // Only Desktop ("installed") clients accept a loopback redirect. A Web client
  // fails later with Google's opaque redirect_uri_mismatch, so reject it here
  // where we can say what is actually wrong.
  if (raw.web && !raw.installed) {
    console.error(
      "This is a Web application OAuth client, not a Desktop app client.\n" +
      `  registered redirect: ${(raw.web.redirect_uris ?? []).join(", ") || "(none)"}\n` +
      `  needed here:         ${cfg.redirect}\n\n` +
      "Web clients only accept redirect URIs registered in the console, which is\n" +
      "why Google returns 'Error 400: redirect_uri_mismatch'.\n\n" +
      "Fix: Google Cloud Console -> Clients -> Create client -> Application type\n" +
      "'Desktop app', then download that JSON and pass it here."
    );
    process.exit(1);
  }
  if (!raw.installed) {
    console.error("Unrecognised OAuth client JSON: expected an 'installed' (Desktop app) client.");
    process.exit(1);
  }
  ({ client_id, client_secret } = raw.installed);
  if (secretsPath === DEFAULT_GOOGLE_OAUTH) {
    console.log("Using Geoffrey's bundled Gmail OAuth app.");
  } else {
    console.log(`Using Google Desktop OAuth client ${client_id.split("-")[0]}`);
  }
} else {
  client_id = arg("client-id");
  if (!client_id && existsSync(DEFAULT_MICROSOFT_OAUTH)) {
    const raw = JSON.parse(readFileSync(DEFAULT_MICROSOFT_OAUTH, "utf8"));
    client_id = raw.client_id;
    if (client_id) console.log("Using Geoffrey's bundled Microsoft OAuth app.");
  }
  if (!client_id) {
    console.error(
      "Missing --client-id <Application (client) ID from Entra>.\n" +
      "Expected bundled config at geoffrey-mcp/config/microsoft-oauth.json, or see docs/outlook-setup.md."
    );
    process.exit(1);
  }
  if (!existsSync(DEFAULT_MICROSOFT_OAUTH)) console.log(`Using Microsoft public client ${client_id}`);
}

const id = arg("id") ?? (await ask("Short id for this account (e.g. work, billing): "));
const purpose = arg("purpose") ?? (await ask("What is this account for? "));

// --- OAuth --------------------------------------------------------------------

const verifier = b64url(randomBytes(48));
const challenge = b64url(createHash("sha256").update(verifier).digest());
const state = b64url(randomBytes(16));

const authUrl = cfg.auth + "?" + new URLSearchParams({
  client_id,
  redirect_uri: cfg.redirect,
  response_type: "code",
  scope: cfg.scope,
  code_challenge: challenge,
  code_challenge_method: "S256",
  state,
  ...(providerName === "google" ? { access_type: "offline", prompt: "consent" } : {}),
});

console.log(`\nOpening ${providerName} consent.`);
if (providerName === "google") {
  console.log("Expect a 'Google hasn't verified this app' warning.");
  console.log("For this friends-and-family Geoffrey setup, click Advanced, then 'Go to Geoffrey (unsafe)'.");
}
console.log(`\nIf the browser does not open:\n${authUrl}\n`);
exec(`open "${authUrl}"`);

const code = await waitForCode(state, cfg.redirect);

const res = await fetch(cfg.token, {
  method: "POST",
  headers: { "Content-Type": "application/x-www-form-urlencoded" },
  body: new URLSearchParams({
    client_id,
    ...(cfg.confidential ? { client_secret } : {}),
    code,
    code_verifier: verifier,
    grant_type: "authorization_code",
    redirect_uri: cfg.redirect,
    ...(providerName === "microsoft" ? { scope: cfg.scope } : {}),
  }),
});

if (!res.ok) {
  console.error(`Token exchange failed (${res.status}):\n${await res.text()}`);
  process.exit(1);
}
const tokens = await res.json();
if (!tokens.refresh_token) {
  console.error("No refresh_token returned. Ensure offline access was requested.");
  process.exit(1);
}

// Confirm the grant actually reaches the API. A token that refreshes but cannot
// read mail is a silent failure that would surface days later.
const who = await cfg.identify(tokens.access_token);

upsertAccount({
  id,
  provider: providerName,
  email: who.email,
  purpose,
  client_id,
  ...(cfg.confidential ? { client_secret } : {}),
  refresh_token: tokens.refresh_token,
  scope: tokens.scope ?? cfg.scope,
  added_at: new Date().toISOString(),
});

console.log(`\nConnected "${id}" → ${who.email} ${who.detail ? `(${who.detail})` : ""}`);
console.log(`Saved to ${storePath()}`);
