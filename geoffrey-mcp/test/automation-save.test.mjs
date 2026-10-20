import assert from "node:assert/strict";
import { execFileSync, spawnSync } from "node:child_process";
import { mkdtempSync, mkdirSync, readFileSync, rmSync, statSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import test from "node:test";

const here = dirname(fileURLToPath(import.meta.url));
const script = join(here, "../bin/automation-save.js");
const inventoryScript = join(here, "../bin/automation-inventory.js");

function setup() {
  const root = mkdtempSync(join(tmpdir(), "geoffrey-save-automation-"));
  const memory = join(root, "memory-repo");
  mkdirSync(join(root, ".geoffrey"), { recursive: true });
  mkdirSync(join(memory, "memory", "automations"), { recursive: true });
  writeFileSync(join(root, ".geoffrey", "current-memory"), memory + "\n");
  writeFileSync(join(root, ".geoffrey", "migration-v1.json"), JSON.stringify({
    private_state: { memory_repository: { automation_candidates: ["memory/social-briefing.md"] } },
  }));
  writeFileSync(join(root, "capabilities.json"), "[]");
  return { root, memory };
}

function payload(overrides = {}) {
  return Buffer.from(JSON.stringify({
    id: "imported-social-briefing",
    name: "Social briefing",
    purpose: "Review social activity three times each day.",
    task: "Review connected social sources and summarize what needs attention.",
    route: "cloud",
    timezone: "America/Denver",
    times: ["08:00", "13:00", "17:00"],
    result_destination: "private_memory",
    approved: true,
    source: { kind: "legacy_memory", path: "memory/social-briefing.md" },
    ...overrides,
  })).toString("base64");
}

test("reviewed workflow is saved portably and replaces its imported candidate", () => {
  const item = setup();
  try {
    const output = execFileSync("node", [script, "--payload", payload()], { env: { ...process.env, HOME: item.root }, encoding: "utf8" });
    const response = JSON.parse(output);
    assert.equal(response.ok, true);
    assert.equal(response.route, "cloud");
    const manifestPath = join(item.memory, "memory", "automations", "manifest.json");
    const manifest = JSON.parse(readFileSync(manifestPath, "utf8"));
    assert.equal(manifest.workflows.length, 1);
    assert.equal(manifest.workflows[0].approval.state, "approved");
    assert.equal(manifest.workflows[0].execution.deployment_state, "not_connected");
    assert.equal(manifest.workflows[0].execution.verified_at, null);
    assert.equal(manifest.workflows[0].result_destination, "private_memory");
    assert.equal(statSync(manifestPath).mode & 0o777, 0o600);

    const inventory = JSON.parse(execFileSync("node", [inventoryScript, "--engine-root", item.root, "--capabilities", join(item.root, "capabilities.json")], {
      env: { ...process.env, HOME: item.root }, encoding: "utf8",
    }));
    assert.equal(inventory.workflows.length, 1);
    assert.equal(inventory.workflows[0].id, "imported-social-briefing");
  } finally {
    rmSync(item.root, { recursive: true, force: true });
  }
});

test("draft stays disabled and credentials are rejected without overwriting it", () => {
  const item = setup();
  try {
    execFileSync("node", [script, "--payload", payload({ approved: false, route: "local" })], { env: { ...process.env, HOME: item.root } });
    const manifestPath = join(item.memory, "memory", "automations", "manifest.json");
    const before = readFileSync(manifestPath, "utf8");
    const rejected = spawnSync("node", [script, "--payload", payload({ task: "Use api_key=sk-ant-SECRET123" })], {
      env: { ...process.env, HOME: item.root }, encoding: "utf8",
    });
    assert.notEqual(rejected.status, 0);
    assert.match(JSON.parse(rejected.stdout).error, /credentials/i);
    assert.equal(readFileSync(manifestPath, "utf8"), before);
    const manifest = JSON.parse(before);
    assert.equal(manifest.workflows[0].enabled, false);
    assert.equal(manifest.workflows[0].execution.preference, "local");
  } finally {
    rmSync(item.root, { recursive: true, force: true });
  }
});

test("unchanged cloud saves retain connection evidence; changed instructions require a cloud update", () => {
  const item = setup();
  try {
    const env = { ...process.env, HOME: item.root };
    execFileSync('node', [script, '--payload', payload()], { env });
    const path = join(item.memory, 'memory/automations/manifest.json');
    const manifest = JSON.parse(readFileSync(path, 'utf8'));
    Object.assign(manifest.workflows[0].execution, { deployment_state: 'active', verified_at: '2026-10-19T12:00:00Z', routine_url: 'https://claude.ai/scheduled-task/trig_example' });
    manifest.removed_workflows = [{ id: 'removed-before', source: { path: 'memory/old-briefing.md' } }];
    writeFileSync(path, JSON.stringify(manifest));
    execFileSync('node', [script, '--payload', payload()], { env });
    let saved = JSON.parse(readFileSync(path, 'utf8'));
    assert.equal(saved.workflows[0].execution.deployment_state, 'active');
    assert.equal(saved.workflows[0].execution.verified_at, '2026-10-19T12:00:00Z');
    assert.equal(saved.removed_workflows[0].id, 'removed-before');
    execFileSync('node', [script, '--payload', payload({ task: 'Updated read-only summary instructions.' })], { env });
    saved = JSON.parse(readFileSync(path, 'utf8'));
    assert.equal(saved.workflows[0].execution.routine_url, 'https://claude.ai/scheduled-task/trig_example');
    assert.equal(saved.workflows[0].execution.deployment_state, 'needs_update');
    assert.equal(saved.workflows[0].execution.verified_at, null);
    writeFileSync(path, '{broken');
    assert.notEqual(spawnSync('node', [script, '--payload', payload()], { env }).status, 0);
    assert.equal(readFileSync(path, 'utf8'), '{broken');
  } finally { rmSync(item.root, { recursive: true, force: true }); }
});
