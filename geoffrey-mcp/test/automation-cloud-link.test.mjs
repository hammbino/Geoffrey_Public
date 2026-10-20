import assert from "node:assert/strict";
import { execFileSync, spawnSync } from "node:child_process";
import { mkdtempSync, mkdirSync, readFileSync, rmSync, statSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import test from "node:test";

const here = dirname(fileURLToPath(import.meta.url));
const script = join(here, "../bin/automation-cloud-link.js");

function setup() {
  const root = mkdtempSync(join(tmpdir(), "geoffrey-cloud-link-"));
  const memory = join(root, "memory-repo");
  mkdirSync(join(root, ".geoffrey"), { recursive: true });
  mkdirSync(join(memory, "memory", "automations"), { recursive: true });
  writeFileSync(join(root, ".geoffrey", "current-memory"), memory + "\n");
  writeFileSync(join(memory, "memory", "automations", "manifest.json"), JSON.stringify({
    schema_version: 1,
    workflows: [{
      id: "social-briefing",
      name: "Social briefing",
      task: "Prepare the approved briefing.",
      enabled: true,
      cadence: { times: ["08:00", "13:00", "17:00"], timezone: "America/Denver" },
      execution: { preference: "cloud", deployment_state: "not_connected", verified_at: null },
      requirements: { cloud_compatible: true, capabilities: [] },
      approval: { state: "approved" },
    }],
  }, null, 2));
  return { root, memory };
}

function payload(overrides = {}) {
  return Buffer.from(JSON.stringify({
    workflow_id: "social-briefing",
    routine_url: "https://claude.ai/code/routines/routine_123",
    connectors_reviewed: true,
    schedule_confirmed: true,
    run_url: "",
    run_reviewed: false,
    ...overrides,
  })).toString("base64");
}

test("approved workflow records a non-secret routine connection without claiming an active run", () => {
  const item = setup();
  try {
    const output = execFileSync("node", [script, "--payload", payload()], { env: { ...process.env, HOME: item.root }, encoding: "utf8" });
    const response = JSON.parse(output);
    assert.equal(response.deployment_state, "connected");
    assert.equal(response.verified_at, null);
    const manifestPath = join(item.memory, "memory", "automations", "manifest.json");
    const workflow = JSON.parse(readFileSync(manifestPath, "utf8")).workflows[0];
    assert.equal(workflow.execution.routine_url, "https://claude.ai/code/routines/routine_123");
    assert.equal(workflow.execution.verification.method, "owner_setup_review");
    assert.equal(workflow.execution.verification.run_url, null);
    assert.equal(statSync(manifestPath).mode & 0o777, 0o600);
  } finally {
    rmSync(item.root, { recursive: true, force: true });
  }
});

test("owner-reviewed run records explicit active evidence", () => {
  const item = setup();
  try {
    const output = execFileSync("node", [script, "--payload", payload({
      run_url: "https://claude.ai/code/session_01TEST",
      run_reviewed: true,
    })], { env: { ...process.env, HOME: item.root }, encoding: "utf8" });
    const response = JSON.parse(output);
    assert.equal(response.deployment_state, "active");
    assert.match(response.verified_at, /^\d{4}-\d{2}-\d{2}T/);
    const workflow = JSON.parse(readFileSync(join(item.memory, "memory", "automations", "manifest.json"), "utf8")).workflows[0];
    assert.equal(workflow.execution.verification.method, "owner_reviewed_run");
    assert.equal(workflow.execution.verification.run_url, "https://claude.ai/code/session_01TEST");
  } finally {
    rmSync(item.root, { recursive: true, force: true });
  }
});

test("current scheduled-task links retain both daily tasks and reject unrelated URLs", () => {
  const item = setup();
  try {
    const morning = "https://claude.ai/scheduled-task/trig_morning";
    const afternoon = "https://claude.ai/scheduled-task/trig_afternoon";
    const output = execFileSync("node", [script, "--payload", payload({
      routine_url: morning, additional_routine_urls: [morning, afternoon, afternoon],
    })], { env: { ...process.env, HOME: item.root }, encoding: "utf8" });
    assert.equal(JSON.parse(output).deployment_state, "connected");
    const path = join(item.memory, "memory", "automations", "manifest.json");
    const before = readFileSync(path, "utf8");
    assert.deepEqual(JSON.parse(before).workflows[0].execution.additional_routine_urls, [afternoon]);
    for (const url of ["https://claude.ai/code/routines", "https://claude.ai/code/session_test", "https://example.com/scheduled-task/trig_other"]) {
      const response = spawnSync("node", [script, "--payload", payload({ additional_routine_urls: [url] })], {
        env: { ...process.env, HOME: item.root }, encoding: "utf8",
      });
      assert.notEqual(response.status, 0);
      assert.equal(readFileSync(path, "utf8"), before);
    }
  } finally {
    rmSync(item.root, { recursive: true, force: true });
  }
});

test("unsafe links and unapproved workflows are rejected without overwriting memory", () => {
  const item = setup();
  try {
    const manifestPath = join(item.memory, "memory", "automations", "manifest.json");
    const before = readFileSync(manifestPath, "utf8");
    const unsafe = spawnSync("node", [script, "--payload", payload({ routine_url: "https://evil.example/code/routines/steal" })], {
      env: { ...process.env, HOME: item.root }, encoding: "utf8",
    });
    assert.notEqual(unsafe.status, 0);
    assert.match(JSON.parse(unsafe.stdout).error, /claude\.ai/i);
    assert.equal(readFileSync(manifestPath, "utf8"), before);

    const manifest = JSON.parse(before);
    manifest.workflows[0].approval.state = "needs_review";
    writeFileSync(manifestPath, JSON.stringify(manifest, null, 2));
    const unapproved = spawnSync("node", [script, "--payload", payload()], { env: { ...process.env, HOME: item.root }, encoding: "utf8" });
    assert.notEqual(unapproved.status, 0);
    assert.match(JSON.parse(unapproved.stdout).error, /approve/i);
  } finally {
    rmSync(item.root, { recursive: true, force: true });
  }
});
