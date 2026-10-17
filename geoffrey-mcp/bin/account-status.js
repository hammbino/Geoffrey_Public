#!/usr/bin/env node

// Returns a small, secret-free account health summary for Geoffrey.app.
import { getAccount, listAccountsForStatus } from "../src/store.js";
import * as google from "../src/providers/google.js";
import * as microsoft from "../src/providers/microsoft.js";

const providers = { google, microsoft };
const requestedIDIndex = process.argv.indexOf("--id");
const requestedID = requestedIDIndex >= 0 ? process.argv[requestedIDIndex + 1] : null;
if (requestedIDIndex >= 0 && !requestedID) {
  console.error("Choose an account to test.");
  process.exit(2);
}
const now = new Date();
const tomorrow = new Date(now);
tomorrow.setDate(tomorrow.getDate() + 1);
const accounts = listAccountsForStatus();
if (requestedID && !accounts.some((account) => account.id === requestedID)) {
  console.error("That account is no longer connected.");
  process.exit(1);
}
const duplicateCounts = new Map();
for (const account of accounts) {
  const email = account.email.toLowerCase();
  duplicateCounts.set(email, (duplicateCounts.get(email) ?? 0) + 1);
}

async function check(account) {
  let hydrated;
  try {
    hydrated = getAccount(account.id);
  } catch {
    return {
      ...account,
      credential_state: "needs_reconnect",
      duplicate_count: duplicateCounts.get(account.email.toLowerCase()) ?? 1,
      mail: {
        state: "needs_reconnect",
        detail: "Reconnect once to protect this account in Keychain",
      },
      calendar: {
        state: "needs_reconnect",
        detail: "Reconnect once to protect this account in Keychain",
      },
    };
  }

  const health = async (operation, readyDetail, reconnectDetail, attentionDetail) => {
    try {
      await operation();
      return { state: "ready", detail: readyDetail };
    } catch (error) {
      const message = String(error.message ?? "");
      const needsReconnect = /calendar access denied|could not refresh access|access denied|keychain credential|macos keychain|\b401\b|invalid_grant/i.test(message);
      return {
        state: needsReconnect ? "needs_reconnect" : "needs_attention",
        detail: needsReconnect ? reconnectDetail : attentionDetail,
      };
    }
  };

  const [mail, calendar] = await Promise.all([
    health(
      () => providers[account.provider].profile(hydrated),
      "Email ready",
      "Reconnect once to restore email access",
      "Email needs attention"
    ),
    health(async () => {
      const result = await providers[account.provider].listEvents(hydrated, {
      calendar_id: "primary",
      time_min: now.toISOString(),
      time_max: tomorrow.toISOString(),
      limit: 1,
      });
      return result;
    }, "Calendar ready", "Reconnect once to restore calendar access", "Calendar needs attention"),
  ]);

  return {
    ...account,
    credential_state: "ready",
    duplicate_count: duplicateCounts.get(account.email.toLowerCase()) ?? 1,
    mail,
    calendar,
  };
}

const selectedAccounts = requestedID ? accounts.filter((account) => account.id === requestedID) : accounts;
const results = await Promise.all(selectedAccounts.map(check));
console.log(JSON.stringify(requestedID ? results[0] : results));
