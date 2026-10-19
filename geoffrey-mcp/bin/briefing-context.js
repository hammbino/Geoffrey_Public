#!/usr/bin/env node

// Prepare fresh, read-only facts for the owner’s local calendar day.
import { listAccounts, getAccount } from "../src/store.js";
import * as google from "../src/providers/google.js";
import * as microsoft from "../src/providers/microsoft.js";
import { buildBriefingContext } from "../src/briefing-context.js";

const index = process.argv.indexOf("--task");
const task = index >= 0 ? process.argv[index + 1] : "daily";
console.log(await buildBriefingContext({
  accounts: listAccounts(), getAccount, providers: { google, microsoft }, task,
}));
