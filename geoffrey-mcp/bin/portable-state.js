#!/usr/bin/env node

// Builds a secret-free recovery map inside the owner's private memory repo.
// It records what should be restored, never the credentials needed to use it.

import { createHash } from "node:crypto";
import { execFileSync } from "node:child_process";
import {
  chmodSync,
  existsSync,
  mkdirSync,
  readFileSync,
  readdirSync,
  renameSync,
  writeFileSync,
} from "node:fs";
import { homedir } from "node:os";
import { basename, dirname, join, relative, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const args = process.argv.slice(2);
const write = args.includes("--write");
const engineIndex = args.indexOf("--engine-root");
const capabilitiesIndex = args.indexOf("--capabilities");
const here = dirname(fileURLToPath(import.meta.url));
const engineRoot = resolve(engineIndex >= 0 ? args[engineIndex + 1] : join(here, "../.."));
const home = homedir();
const store = join(home, ".geoffrey");
const pointer = join(store, "current-memory");
const accountsPath = join(store, "accounts.json");
const memoryRoot = existsSync(pointer) ? readFileSync(pointer, "utf8").split(/\r?\n/, 1)[0].trim() : "";
const manifestPath = memoryRoot ? join(memoryRoot, "memory", "portable-state.json") : "";

function readJson(path, fallback) {
  try { return JSON.parse(readFileSync(path, "utf8")); } catch { return fallback; }
}

function hash(path) {
  return createHash("sha256").update(readFileSync(path)).digest("hex");
}

function sanitizeRemote(remote) {
  if (!remote) return null;
  try {
    const url = new URL(remote);
    url.username = "";
    url.password = "";
    url.search = "";
    url.hash = "";
    return url.toString();
  } catch {
    return remote.replace(/\/\/[^/@]+@/, "//");
  }
}

function repositoryMetadata() {
  const configPath = join(memoryRoot, ".git", "config");
  const headPath = join(memoryRoot, ".git", "HEAD");
  const config = existsSync(configPath) ? readFileSync(configPath, "utf8") : "";
  const head = existsSync(headPath) ? readFileSync(headPath, "utf8").trim() : "";
  const remote = config.match(/\[remote "origin"\][\s\S]*?\n\s*url\s*=\s*(.+)/)?.[1]?.trim();
  return {
    remote: sanitizeRemote(remote),
    branch: head.startsWith("ref: refs/heads/") ? head.slice("ref: refs/heads/".length) : null,
  };
}

function skillFiles() {
  const found = [];
  const markdownDirectory = join(memoryRoot, "memory", "skills");
  if (existsSync(markdownDirectory)) {
    for (const entry of readdirSync(markdownDirectory, { withFileTypes: true })) {
      if (!entry.isFile() || !entry.name.endsWith(".md")) continue;
      found.push({ name: basename(entry.name, ".md"), format: "geoffrey_markdown", path: join(markdownDirectory, entry.name) });
    }
  }
  const claudeDirectory = join(memoryRoot, ".claude", "skills");
  if (existsSync(claudeDirectory)) {
    for (const entry of readdirSync(claudeDirectory, { withFileTypes: true })) {
      const path = join(claudeDirectory, entry.name, "SKILL.md");
      if (!entry.isDirectory() || !existsSync(path)) continue;
      found.push({ name: entry.name, format: "claude_skill", path });
    }
  }
  return found
    .map((skill) => ({
      id: `skill:${skill.name}`,
      name: skill.name,
      format: skill.format,
      path: relative(memoryRoot, skill.path),
      sha256: hash(skill.path),
      approved: true,
      approval_basis: "stored_in_private_memory",
    }))
    .sort((a, b) => a.id.localeCompare(b.id));
}

function capabilities() {
  if (capabilitiesIndex >= 0) return readJson(resolve(args[capabilitiesIndex + 1]), []);
  try {
    return JSON.parse(execFileSync(process.execPath, [join(here, "capability-inventory.js"), "--engine-root", engineRoot], {
      encoding: "utf8",
      stdio: ["ignore", "pipe", "ignore"],
    }));
  } catch {
    return [];
  }
}

function connectorDefinitions() {
  const accountFile = readJson(accountsPath, { accounts: [] });
  const accounts = Array.isArray(accountFile.accounts) ? accountFile.accounts : [];
  const connectors = accounts.map(({ id, provider, email, purpose }) => ({
    id: `account:${id}`,
    name: purpose || id,
    kind: "email_calendar",
    provider: provider || "unknown",
    account: email || null,
    capabilities: ["email", "calendar"],
    approved: true,
    restore_action: "sign_in_again",
    secret_included: false,
  }));
  for (const capability of capabilities()) {
    if (!['mcp', 'plugin'].includes(capability.type)) continue;
    connectors.push({
      id: capability.id,
      name: capability.name,
      kind: capability.type,
      provider: "claude",
      capabilities: [],
      approved: capability.enabled === true,
      restore_action: capability.type === "mcp" ? "reconnect_in_claude" : "reinstall_or_enable_in_claude",
      secret_included: false,
    });
  }
  return connectors.sort((a, b) => a.id.localeCompare(b.id));
}

function comparable(value) {
  if (!value || typeof value !== "object") return value;
  const copy = structuredClone(value);
  delete copy.updated_at;
  return copy;
}

function status(state, manifest, message, recovery = null) {
  const connectors = manifest?.connectors ?? [];
  return {
    schema_version: 1,
    state,
    updated_at: manifest?.updated_at ?? null,
    manifest_path: manifestPath ? relative(memoryRoot, manifestPath) : null,
    skills_count: manifest?.skills?.length ?? 0,
    connectors_count: connectors.length,
    reconnect_count: connectors.filter((item) => item.restore_action).length,
    message,
    recovery,
  };
}

if (!memoryRoot || !existsSync(join(memoryRoot, "memory"))) {
  console.log(JSON.stringify(status("not_configured", null, "Create private Geoffrey memory before preparing recovery information.")));
  process.exit(0);
}

const repository = repositoryMetadata();
const candidate = {
  schema_version: 1,
  geoffrey_minimum_version: "0.11.0",
  repository,
  skills: skillFiles(),
  connectors: connectorDefinitions(),
  restore: {
    format_version: 1,
    memory_strategy: "clone_private_repository",
    credentials_strategy: "sign_in_again_on_new_mac",
    secrets_included: false,
    automation_manifest: existsSync(join(memoryRoot, "memory", "automations", "manifest.json"))
      ? "memory/automations/manifest.json"
      : null,
  },
};
const existing = readJson(manifestPath, null);

if (write) {
  const manifest = { ...candidate, updated_at: new Date().toISOString() };
  mkdirSync(dirname(manifestPath), { recursive: true, mode: 0o700 });
  const temporary = manifestPath + ".tmp";
  writeFileSync(temporary, JSON.stringify(manifest, null, 2) + "\n", { mode: 0o600 });
  chmodSync(temporary, 0o600);
  renameSync(temporary, manifestPath);
  chmodSync(manifestPath, 0o600);
  console.log(JSON.stringify(status("ready", manifest, "Recovery information is current and contains no credentials.")));
  process.exit(0);
}

if (!existing) {
  console.log(JSON.stringify(status("needs_update", candidate, "Recovery information has not been prepared yet.", "Choose Update recovery map. Geoffrey will save only non-secret setup information.")));
} else if (JSON.stringify(comparable(existing)) !== JSON.stringify(comparable(candidate))) {
  console.log(JSON.stringify(status("needs_update", existing, "Skills or connections changed since the recovery information was prepared.", "Choose Update recovery map before relying on this backup.")));
} else {
  console.log(JSON.stringify(status("ready", existing, "Recovery information is current and contains no credentials.")));
}
