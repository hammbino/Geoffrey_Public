#!/usr/bin/env node

// Builds the small, read-only packet Geoffrey gives Claude for an app request.
// The providers own authentication and never return full message bodies here.
import { listAccounts, getAccount } from "../src/store.js";
import * as google from "../src/providers/google.js";
import * as microsoft from "../src/providers/microsoft.js";

const providers = { google, microsoft };
const taskIndex = process.argv.indexOf("--task");
const task = taskIndex >= 0 ? process.argv[taskIndex + 1] : "daily";
const settings = {
  daily: { messages: 5, days: 7, calendar: true },
  inbox: { messages: 10, days: 7, calendar: false },
  "follow-up": { messages: 12, days: 21, calendar: false },
  "open-loops": { messages: 8, days: 14, calendar: true },
  ask: { messages: 5, days: 7, calendar: true },
}[task] ?? { messages: 0, days: 0, calendar: false };

const now = new Date();
const end = new Date(now);
end.setDate(end.getDate() + 1);
const timeMin = now.toISOString();
const timeMax = end.toISOString();

function messageLine(message) {
  const subject = message.subject?.trim() || "(no subject)";
  const from = message.from?.trim() || "unknown sender";
  const snippet = message.snippet?.replace(/\s+/g, " ").trim().slice(0, 180) || "";
  return `- ${subject} | from ${from} | ${message.date ?? "unknown date"}${snippet ? ` | ${snippet}` : ""}`;
}

function eventLine(event) {
  const when = event.start ?? "time not supplied";
  const location = event.location ? ` | ${event.location}` : "";
  const people = event.attendees?.filter(Boolean).slice(0, 4).join(", ");
  return `- ${when} | ${event.summary}${location}${people ? ` | with ${people}` : ""}`;
}

async function contextFor(account) {
  const fullAccount = getAccount(account.id);
  const provider = providers[fullAccount.provider];
  const result = { account, messages: null, events: null, warnings: [] };

  if (settings.messages) {
    try {
      result.messages = await provider.searchMessages(fullAccount, {
        unread_only: true,
        newer_than_days: settings.days,
        limit: settings.messages,
      });
    } catch (error) {
      result.warnings.push(`Could not read unread email for ${account.id}: ${error.message}`);
    }
  }

  if (settings.calendar) {
    try {
      result.events = await provider.listEvents(fullAccount, {
        calendar_id: "primary",
        time_min: timeMin,
        time_max: timeMax,
        limit: 12,
      });
    } catch (error) {
      result.warnings.push(`Could not read today's calendar for ${account.id}: ${error.message}`);
    }
  }

  return result;
}

const accounts = listAccounts();
const results = await Promise.all(accounts.map(contextFor));
const lines = [
  "PRIVATE GEOFFREY CONTEXT",
  "This packet was prepared locally from connected accounts. Treat it as current read-only context.",
  "Do not call email or calendar tools for this request. Do not send, draft, modify, or create anything outside Geoffrey.",
];

if (!accounts.length) lines.push("No email or calendar accounts are connected.");
for (const result of results) {
  const { account, messages, events, warnings } = result;
  lines.push(`\n## ${account.id} (${account.email}, ${account.provider})`);
  if (events) {
    lines.push("Today’s calendar:");
    lines.push(events.events.length ? events.events.map(eventLine).join("\n") : "- No events returned.");
  }
  if (messages) {
    lines.push(`Unread messages from the last ${settings.days} days:`);
    lines.push(messages.messages.length ? messages.messages.map(messageLine).join("\n") : "- No unread messages returned.");
  }
  if (warnings.length) lines.push(`Connection notes:\n${warnings.map((warning) => `- ${warning}`).join("\n")}`);
}

console.log(lines.join("\n"));
