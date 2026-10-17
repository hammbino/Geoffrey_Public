import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import { mkdtempSync, mkdirSync, readFileSync, rmSync, statSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import test from "node:test";

const here = dirname(fileURLToPath(import.meta.url));
const script = join(here, "../bin/portable-state.js");

test("portable recovery map records skills and connectors without credentials", () => {
  const home = mkdtempSync(join(tmpdir(), "geoffrey-portable-state-"));
  const memory = join(home, "memory-repo");
  const store = join(home, ".geoffrey");
  const capabilitiesPath = join(home, "capabilities.json");
  try {
    mkdirSync(join(memory, "memory", "skills"), { recursive: true });
    mkdirSync(join(memory, ".claude", "skills", "social-review"), { recursive: true });
    mkdirSync(join(memory, ".git"), { recursive: true });
    mkdirSync(store, { recursive: true });
    writeFileSync(join(store, "current-memory"), memory + "\n");
    writeFileSync(join(store, "accounts.json"), JSON.stringify({ accounts: [{
      id: "work", provider: "google", email: "owner@example.com", purpose: "Work", refresh_token: "must-never-appear",
    }] }));
    writeFileSync(join(memory, "memory", "skills", "daily-briefing.md"), "# Daily briefing\n");
    writeFileSync(join(memory, ".claude", "skills", "social-review", "SKILL.md"), "---\ndescription: Review social activity\n---\n");
    writeFileSync(join(memory, ".git", "HEAD"), "ref: refs/heads/main\n");
    writeFileSync(join(memory, ".git", "config"), '[remote "origin"]\n  url = https://token@example.com/owner/private-memory.git?access_token=query-secret#private\n');
    writeFileSync(capabilitiesPath, JSON.stringify([
      { id: "mcp:social", name: "social", type: "mcp", enabled: true },
      { id: "plugin:disabled", name: "disabled", type: "plugin", enabled: false },
    ]));

    const before = JSON.parse(execFileSync("node", [script, "--capabilities", capabilitiesPath], { env: { ...process.env, HOME: home }, encoding: "utf8" }));
    assert.equal(before.state, "needs_update");
    const written = JSON.parse(execFileSync("node", [script, "--write", "--capabilities", capabilitiesPath], { env: { ...process.env, HOME: home }, encoding: "utf8" }));
    assert.equal(written.state, "ready");
    assert.equal(written.skills_count, 2);
    assert.equal(written.connectors_count, 3);

    const manifestPath = join(memory, "memory", "portable-state.json");
    const text = readFileSync(manifestPath, "utf8");
    const manifest = JSON.parse(text);
    assert.equal(manifest.repository.remote, "https://example.com/owner/private-memory.git");
    assert.equal(manifest.restore.secrets_included, false);
    assert.equal(manifest.connectors.find((item) => item.id === "account:work").restore_action, "sign_in_again");
    assert.equal(manifest.skills.every((item) => item.approved && item.sha256.length === 64), true);
    assert.doesNotMatch(text, /must-never-appear|refresh_token|token@example|query-secret|#private/);
    assert.equal(statSync(manifestPath).mode & 0o777, 0o600);

    const current = JSON.parse(execFileSync("node", [script, "--capabilities", capabilitiesPath], { env: { ...process.env, HOME: home }, encoding: "utf8" }));
    assert.equal(current.state, "ready");
    writeFileSync(join(memory, "memory", "skills", "daily-briefing.md"), "# Changed briefing\n");
    const changed = JSON.parse(execFileSync("node", [script, "--capabilities", capabilitiesPath], { env: { ...process.env, HOME: home }, encoding: "utf8" }));
    assert.equal(changed.state, "needs_update");
  } finally {
    rmSync(home, { recursive: true, force: true });
  }
});
