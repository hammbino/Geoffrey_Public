#!/usr/bin/env node

import { execFileSync } from "node:child_process";
import { existsSync, readFileSync, readdirSync } from "node:fs";
import { homedir } from "node:os";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const engineIndex = process.argv.indexOf("--engine-root");
const engineRoot = resolve(engineIndex >= 0 ? process.argv[engineIndex + 1] : join(here, "../.."));
const home = homedir();
const pointer = join(home, ".geoffrey", "current-memory");
const memoryRoot = existsSync(pointer) ? readFileSync(pointer, "utf8").split(/\r?\n/, 1)[0].trim() : "";
const capabilities = [];
const seenSkills = new Set();

function skillMetadata(path, source) {
  if (!existsSync(path)) return;
  for (const entry of readdirSync(path, { withFileTypes: true })) {
    if (!entry.isDirectory()) continue;
    const file = join(path, entry.name, "SKILL.md");
    if (!existsSync(file) || seenSkills.has(entry.name)) continue;
    const text = readFileSync(file, "utf8");
    const description = text.match(/^description:\s*(.+)$/m)?.[1]?.trim() ?? "Claude skill";
    capabilities.push({
      id: `skill:${entry.name}`,
      name: entry.name,
      type: "skill",
      source,
      enabled: true,
      state: "ready",
      repair: "none",
      description,
    });
    seenSkills.add(entry.name);
  }
}

// User and memory skills take precedence over Geoffrey's bundled defaults.
skillMetadata(join(home, ".claude", "skills"), "Claude account");
if (memoryRoot) skillMetadata(join(memoryRoot, ".claude", "skills"), "Private memory");
skillMetadata(join(engineRoot, ".claude", "skills"), "Geoffrey");

try {
  const plugins = JSON.parse(execFileSync("claude", ["plugin", "list", "--json"], { encoding: "utf8", stdio: ["ignore", "pipe", "ignore"] }));
  for (const plugin of plugins) {
    capabilities.push({
      id: `plugin:${plugin.id}`,
      name: plugin.id.split("@")[0],
      type: "plugin",
      source: plugin.scope ?? "Claude",
      enabled: plugin.enabled !== false,
      state: plugin.enabled === false ? "disabled" : "ready",
      repair: plugin.enabled === false ? "enable_plugin" : "none",
      description: plugin.enabled === false ? "Installed but disabled" : "Installed Claude plugin",
    });
  }
} catch { /* Claude may be signed out or an older version may lack plugin JSON. */ }

try {
  const output = execFileSync("claude", ["mcp", "list"], { encoding: "utf8", stdio: ["ignore", "pipe", "ignore"] });
  for (const line of output.split(/\r?\n/)) {
    const match = line.match(/^\s*([^:]+):\s*(.+)$/);
    if (!match || /No MCP servers configured/i.test(line)) continue;
    const name = match[1].replace(/^[^\w]+/, "").trim();
    if (!name) continue;
    const description = match[2].trim();
    let state = "needs_attention";
    let repair = "review_mcp";
    if (/connected|[✔✓]/i.test(description)) {
      state = "ready";
      repair = "none";
    } else if (/pending/i.test(description)) {
      state = "pending";
    } else if (/login|auth|unauthori[sz]ed/i.test(description)) {
      state = "needs_login";
      repair = "login_mcp";
    } else if (/disabled/i.test(description)) {
      state = "disabled";
    }
    capabilities.push({
      id: `mcp:${name}`,
      name,
      type: "mcp",
      source: "Claude",
      enabled: state === "ready",
      state,
      repair,
      description,
    });
  }
} catch { /* An unavailable MCP health check should not hide skills/plugins. */ }

capabilities.sort((a, b) => a.type.localeCompare(b.type) || a.name.localeCompare(b.name));
console.log(JSON.stringify(capabilities));
