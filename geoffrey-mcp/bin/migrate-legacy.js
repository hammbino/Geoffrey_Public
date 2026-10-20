#!/usr/bin/env node

// Creates a secret-free migration inventory and a recoverable local backup of
// terminal-era Geoffrey state. Private data stays in ~/.geoffrey and in the
// user's existing GitHub-backed memory repository; nothing is uploaded here.

import {
  chmodSync,
  copyFileSync,
  existsSync,
  mkdirSync,
  readFileSync,
  readdirSync,
  renameSync,
  writeFileSync,
} from "node:fs";
import { createHash } from "node:crypto";
import { homedir } from "node:os";
import { basename, dirname, join, relative, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { isAutomationCandidatePath } from "../src/automation-inventory.js";

const args = process.argv.slice(2);
const write = args.includes("--write");
const engineIndex = args.indexOf("--engine-root");
const here = dirname(fileURLToPath(import.meta.url));
const engineRoot = resolve(engineIndex >= 0 ? args[engineIndex + 1] : join(here, "../.."));
const home = homedir();
const store = join(home, ".geoffrey");
const accountsPath = join(store, "accounts.json");
const memoryPointerPath = join(store, "current-memory");
const manifestPath = join(store, "migration-v1.json");
const backupPath = join(store, "backups", "pre-desktop-v1");
const legacyRoot = join(home, "Geoffrey");

function sha256(path) {
  if (!existsSync(path)) return null;
  return createHash("sha256").update(readFileSync(path)).digest("hex");
}

function readJson(path) {
  try { return JSON.parse(readFileSync(path, "utf8")); } catch { return null; }
}

function sanitizeRemote(remote) {
  if (!remote) return null;
  try {
    const url = new URL(remote);
    url.username = "";
    url.password = "";
    return url.toString();
  } catch {
    return remote.replace(/\/\/[^/@]+@/, "//");
  }
}

function gitRemote(memoryPath) {
  const config = join(memoryPath, ".git", "config");
  if (!existsSync(config)) return null;
  const text = readFileSync(config, "utf8");
  const origin = text.match(/\[remote "origin"\][\s\S]*?\n\s*url\s*=\s*(.+)/);
  return sanitizeRemote(origin?.[1]?.trim());
}

function findAutomationFiles(memoryPath) {
  if (!memoryPath || !existsSync(memoryPath)) return [];
  const found = [];
  const queue = [memoryPath];
  while (queue.length && found.length < 100) {
    const current = queue.shift();
    let entries = [];
    try { entries = readdirSync(current, { withFileTypes: true }); } catch { continue; }
    for (const entry of entries) {
      if (entry.name === ".git" || entry.name === "node_modules") continue;
      const path = join(current, entry.name);
      if (entry.isDirectory()) queue.push(path);
      if (entry.isFile() && isAutomationCandidatePath(relative(memoryPath, path))) {
        found.push(relative(memoryPath, path));
      }
    }
  }
  return found.sort();
}

const rawAccounts = readJson(accountsPath);
const accounts = Array.isArray(rawAccounts?.accounts) ? rawAccounts.accounts : [];
const memoryPath = existsSync(memoryPointerPath)
  ? readFileSync(memoryPointerPath, "utf8").split(/\r?\n/, 1)[0].trim()
  : "";
const memoryExists = Boolean(memoryPath && existsSync(join(memoryPath, "memory")));
const legacyExists = existsSync(join(legacyRoot, "bin", "geoffrey"));

const manifest = {
  schema_version: 1,
  state: accounts.length || memoryExists || legacyExists ? "migrated" : "fresh_install",
  generated_at: new Date().toISOString(),
  engine: {
    path: engineRoot,
    self_contained: !engineRoot.startsWith(legacyRoot + "/") && engineRoot !== legacyRoot,
  },
  legacy_install: {
    path: legacyRoot,
    exists: legacyExists,
    git_checkout: existsSync(join(legacyRoot, ".git")),
    update_job: existsSync(join(home, "Library", "LaunchAgents", "com.geoffrey.update-check.plist")),
  },
  private_state: {
    store,
    accounts: {
      exists: existsSync(accountsPath),
      count: accounts.length,
      sha256: sha256(accountsPath),
      entries: accounts.map(({ id, provider, email, purpose }) => ({ id, provider, email, purpose })),
    },
    memory_pointer: {
      exists: existsSync(memoryPointerPath),
      path: memoryPath || null,
      sha256: sha256(memoryPointerPath),
    },
    memory_repository: {
      exists: memoryExists,
      git_checkout: Boolean(memoryPath && existsSync(join(memoryPath, ".git"))),
      remote: memoryPath ? gitRemote(memoryPath) : null,
      automation_candidates: findAutomationFiles(memoryPath),
    },
  },
  claude: {
    user_config_present: existsSync(join(home, ".claude.json")) || existsSync(join(home, ".claude")),
  },
};

if (write) {
  mkdirSync(store, { recursive: true, mode: 0o700 });
  chmodSync(store, 0o700);
  mkdirSync(backupPath, { recursive: true, mode: 0o700 });
  chmodSync(backupPath, 0o700);
  for (const source of [accountsPath, memoryPointerPath]) {
    if (!existsSync(source)) continue;
    const destination = join(backupPath, basename(source));
    if (!existsSync(destination)) copyFileSync(source, destination);
    chmodSync(destination, 0o600);
  }
  const temporary = manifestPath + ".tmp";
  writeFileSync(temporary, JSON.stringify(manifest, null, 2) + "\n", { mode: 0o600 });
  chmodSync(temporary, 0o600);
  renameSync(temporary, manifestPath);
}

console.log(JSON.stringify(manifest));
