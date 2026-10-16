#!/usr/bin/env node

// Queues missed, explicitly approved local workflows. This command never runs
// Claude or a workflow and never creates or modifies a cloud schedule.

import { execFileSync } from "node:child_process";
import { chmodSync, existsSync, mkdirSync, readFileSync, renameSync, writeFileSync } from "node:fs";
import { homedir } from "node:os";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { queueMissedLocalRuns } from "../src/automation-inventory.js";

const here = dirname(fileURLToPath(import.meta.url));
const args = process.argv.slice(2);
const engineIndex = args.indexOf("--engine-root");
const engineRoot = resolve(engineIndex >= 0 ? args[engineIndex + 1] : join(here, "../.."));
const write = args.includes("--write");
const home = homedir();
const store = join(home, ".geoffrey");
const pointer = join(store, "current-memory");
const memoryRoot = existsSync(pointer) ? readFileSync(pointer, "utf8").split(/\r?\n/, 1)[0].trim() : "";

function readJson(path) {
  try { return JSON.parse(readFileSync(path, "utf8")); } catch { return null; }
}

const manifestCandidates = [
  memoryRoot && join(memoryRoot, "memory", "automations", "manifest.json"),
  memoryRoot && join(memoryRoot, "automations", "manifest.json"),
  join(store, "automations", "manifest.json"),
].filter(Boolean);
const manifestPath = manifestCandidates.find((path) => existsSync(path));
const queuePath = join(store, "automations", "queue.json");
let capabilities = [];
try {
  capabilities = JSON.parse(execFileSync("node", [join(here, "capability-inventory.js"), "--engine-root", engineRoot], {
    encoding: "utf8",
    stdio: ["ignore", "pipe", "ignore"],
  }));
} catch { /* Missing capabilities prevent unsafe cloud routing; local dependencies remain explicit. */ }

const result = queueMissedLocalRuns({
  manifest: manifestPath ? readJson(manifestPath) : null,
  queue: readJson(queuePath),
  capabilities,
});

if (write && manifestPath) {
  mkdirSync(dirname(queuePath), { recursive: true, mode: 0o700 });
  chmodSync(dirname(queuePath), 0o700);
  const temporary = queuePath + ".tmp";
  writeFileSync(temporary, JSON.stringify(result, null, 2) + "\n", { mode: 0o600 });
  chmodSync(temporary, 0o600);
  renameSync(temporary, queuePath);
}

console.log(JSON.stringify(result));
