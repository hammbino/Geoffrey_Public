#!/usr/bin/env node

// Read-only automation discovery for Geoffrey.app. It reports safe metadata
// from private memory and migration state; it never creates or changes a job.

import { execFileSync } from "node:child_process";
import { existsSync, readFileSync } from "node:fs";
import { homedir } from "node:os";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { buildAutomationInventory } from "../src/automation-inventory.js";

const here = dirname(fileURLToPath(import.meta.url));
const args = process.argv.slice(2);
const engineIndex = args.indexOf("--engine-root");
const capabilitiesIndex = args.indexOf("--capabilities");
const engineRoot = resolve(engineIndex >= 0 ? args[engineIndex + 1] : join(here, "../.."));
const home = homedir();
const store = join(home, ".geoffrey");

function readJson(path) {
  try { return JSON.parse(readFileSync(path, "utf8")); } catch { return null; }
}

const pointer = join(store, "current-memory");
const memoryRoot = existsSync(pointer) ? readFileSync(pointer, "utf8").split(/\r?\n/, 1)[0].trim() : "";
const manifestCandidates = [
  memoryRoot && join(memoryRoot, "memory", "automations", "manifest.json"),
  memoryRoot && join(memoryRoot, "automations", "manifest.json"),
  join(store, "automations", "manifest.json"),
].filter(Boolean);
const manifestPath = manifestCandidates.find((path) => existsSync(path)) ?? null;
const migration = readJson(join(store, "migration-v1.json"));
const queue = readJson(join(store, "automations", "queue.json"));
const portableHistoryPath = memoryRoot && join(memoryRoot, "memory", "automations", "history.json");
const history = readJson(portableHistoryPath) ?? readJson(join(store, "automations", "history.json"));

let capabilities = [];
if (capabilitiesIndex >= 0) {
  capabilities = readJson(resolve(args[capabilitiesIndex + 1])) ?? [];
} else {
  try {
    capabilities = JSON.parse(execFileSync("node", [join(here, "capability-inventory.js"), "--engine-root", engineRoot], {
      encoding: "utf8",
      stdio: ["ignore", "pipe", "ignore"],
    }));
  } catch { /* Missing Claude capability metadata leaves workflows in review. */ }
}

const inventory = buildAutomationInventory({
  manifest: manifestPath ? readJson(manifestPath) : null,
  migration,
  queue,
  history,
  capabilities,
  sourcePath: manifestPath && memoryRoot && manifestPath.startsWith(memoryRoot)
    ? manifestPath.slice(memoryRoot.length + 1)
    : manifestPath,
});

console.log(JSON.stringify(inventory));
