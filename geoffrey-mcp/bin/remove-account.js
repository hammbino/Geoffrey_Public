#!/usr/bin/env node

import { removeAccount } from "../src/store.js";

const index = process.argv.indexOf("--id");
const id = index >= 0 ? process.argv[index + 1] : "";
if (!id) {
  console.error("An account id is required.");
  process.exit(2);
}

const account = removeAccount(id);
console.log(`Removed ${account.id}.`);
