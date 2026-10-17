#!/usr/bin/env node

// Returns a small, secret-free account health summary for Geoffrey.app.
import { getAccount, listAccountsForStatus } from "../src/store.js";
import * as google from "../src/providers/google.js";
import * as microsoft from "../src/providers/microsoft.js";

const providers = { google, microsoft };
const now = new Date();
const tomorrow = new Date(now);
tomorrow.setDate(tomorrow.getDate() + 1);
const accounts = listAccountsForStatus();
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
      calendar: {
        state: "needs_reconnect",
        detail: "Reconnect once to protect this account in Keychain",
      },
    };
  }

  try {
    const result = await providers[account.provider].listEvents(hydrated, {
      calendar_id: "primary",
      time_min: now.toISOString(),
      time_max: tomorrow.toISOString(),
      limit: 1,
    });
    return {
      ...account,
      credential_state: "ready",
      duplicate_count: duplicateCounts.get(account.email.toLowerCase()) ?? 1,
      calendar: {
        state: "ready",
        detail: result.events.length ? "Calendar ready" : "Calendar ready; no events today",
      },
    };
  } catch (error) {
    const message = String(error.message ?? "");
    const needsReconnect = /calendar access denied|could not refresh access|access denied|keychain credential|macos keychain/i.test(message);
    return {
      ...account,
      credential_state: "ready",
      duplicate_count: duplicateCounts.get(account.email.toLowerCase()) ?? 1,
      calendar: {
        state: needsReconnect ? "needs_reconnect" : "needs_attention",
        detail: needsReconnect
          ? "Reconnect once to add calendar access"
          : "Calendar needs attention",
      },
    };
  }
}

console.log(JSON.stringify(await Promise.all(accounts.map(check))));
