import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import { mkdtempSync, mkdirSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import test from "node:test";
import { queueMissedLocalRuns } from "../src/automation-inventory.js";

const here = dirname(fileURLToPath(import.meta.url));
const script = join(here, "../bin/automation-inventory.js");

test("automation inventory discovers migrated work and classifies cloud, local, and review routes", () => {
  const root = mkdtempSync(join(tmpdir(), "geoffrey-automations-"));
  const memory = join(root, "memory-repo");
  const store = join(root, ".geoffrey");
  try {
    mkdirSync(join(memory, "memory", "automations"), { recursive: true });
    mkdirSync(join(store, "automations"), { recursive: true });
    writeFileSync(join(store, "current-memory"), memory + "\n");
    writeFileSync(join(store, "migration-v1.json"), JSON.stringify({
      private_state: { memory_repository: { automation_candidates: ["memory/social-briefing.md"] } },
    }));
    writeFileSync(join(memory, "memory", "automations", "manifest.json"), JSON.stringify({
      schema_version: 1,
      workflows: [
        {
          id: "cloud-brief",
          name: "Cloud briefing",
          purpose: "Prepare a briefing",
          cadence: { times: ["08:00", "13:00", "17:00"], timezone: "America/Denver" },
          execution: { preference: "cloud" },
          requirements: { cloud_compatible: true, capabilities: ["mcp:social"] },
          approval: { state: "approved" },
          enabled: true,
        },
        {
          id: "local-files",
          name: "Local file review",
          execution: { preference: "auto" },
          requirements: { cloud_compatible: false, local_paths: ["~/Documents"] },
          approval: { state: "approved" },
          enabled: true,
        },
        {
          id: "missing-tool",
          name: "Missing connector",
          execution: { preference: "cloud" },
          requirements: { cloud_compatible: true, capabilities: ["mcp:missing"] },
          approval: { state: "approved" },
          enabled: true,
        },
      ],
    }));
    writeFileSync(join(store, "automations", "queue.json"), JSON.stringify({
      items: [{ workflow_id: "local-files" }, { workflow_id: "local-files" }],
    }));
    const capabilitiesPath = join(root, "capabilities.json");
    writeFileSync(capabilitiesPath, JSON.stringify([{ id: "mcp:social", name: "social", state: "ready", enabled: true }]));
    writeFileSync(join(memory, "private-token.txt"), "ghp_THIS_MUST_NEVER_APPEAR");

    const output = execFileSync("node", [script, "--engine-root", root, "--capabilities", capabilitiesPath], {
      env: { ...process.env, HOME: root },
      encoding: "utf8",
    });
    const result = JSON.parse(output);
    assert.equal(result.workflows.length, 4);
    assert.equal(result.workflows.find(({ id }) => id === "cloud-brief").execution.route, "cloud");
    assert.equal(result.workflows.find(({ id }) => id === "local-files").execution.route, "local");
    assert.equal(result.workflows.find(({ id }) => id === "local-files").status.queued_runs, 2);
    assert.equal(result.workflows.find(({ id }) => id === "missing-tool").execution.route, "review");
    assert.equal(result.workflows.find(({ source }) => source.kind === "legacy_memory").approval.state, "needs_review");
    assert.equal(result.summary.cloud, 1);
    assert.equal(result.summary.local, 1);
    assert.equal(result.summary.queued_runs, 2);
    assert.equal(output.includes("ghp_THIS_MUST_NEVER_APPEAR"), false);
    assert.equal(result.execution_available, false);
  } finally {
    rmSync(root, { recursive: true, force: true });
  }
});

test("unreviewed cloud-compatible work remains disabled", () => {
  const root = mkdtempSync(join(tmpdir(), "geoffrey-automation-approval-"));
  const memory = join(root, "memory-repo");
  const store = join(root, ".geoffrey");
  try {
    mkdirSync(join(memory, "memory", "automations"), { recursive: true });
    mkdirSync(store, { recursive: true });
    writeFileSync(join(store, "current-memory"), memory + "\n");
    writeFileSync(join(memory, "memory", "automations", "manifest.json"), JSON.stringify({
      workflows: [{
        id: "candidate",
        name: "Candidate",
        enabled: true,
        execution: { preference: "cloud" },
        requirements: { cloud_compatible: true },
        approval: { state: "needs_review" },
      }],
    }));
    const capabilitiesPath = join(root, "capabilities.json");
    writeFileSync(capabilitiesPath, "[]");
    const result = JSON.parse(execFileSync("node", [script, "--engine-root", root, "--capabilities", capabilitiesPath], {
      env: { ...process.env, HOME: root }, encoding: "utf8",
    }));
    assert.equal(result.workflows[0].execution.route, "cloud");
    assert.equal(result.workflows[0].enabled, false);
    assert.equal(result.workflows[0].status.state, "needs_review");
  } finally {
    rmSync(root, { recursive: true, force: true });
  }
});

test("missed local runs are queued only for approved enabled workflows and are bounded", () => {
  const manifest = {
    workflows: [
      {
        id: "approved-local",
        enabled: true,
        approval: { state: "approved" },
        cadence: { times: ["08:00", "13:00", "17:00"], timezone: "America/Denver" },
        execution: { preference: "local" },
        requirements: { local_paths: ["~/Documents"] },
      },
      {
        id: "not-approved",
        enabled: true,
        approval: { state: "needs_review" },
        cadence: { times: ["13:00"], timezone: "America/Denver" },
        execution: { preference: "local" },
        requirements: { local_paths: ["~/Documents"] },
      },
    ],
  };
  const now = new Date("2026-10-16T23:30:00.000Z"); // 5:30 PM in Denver.
  const result = queueMissedLocalRuns({
    manifest,
    queue: { last_checked_at: "2026-10-16T13:30:00.000Z", items: [] },
    capabilities: [],
    now,
  });
  assert.deepEqual(result.items.map((item) => item.workflow_id), ["approved-local", "approved-local", "approved-local"]);
  assert.equal(result.added, 3);
  const repeated = queueMissedLocalRuns({ manifest, queue: result, capabilities: [], now });
  assert.equal(repeated.added, 0);
});
