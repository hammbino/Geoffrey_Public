import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { chmodSync, mkdtempSync, mkdirSync, readFileSync, rmSync, statSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import test from "node:test";

const here = dirname(fileURLToPath(import.meta.url));
const script = join(here, "../bin/automation-run.js");

function fixture({ approved = true, route = "local", fakeExit = 0 } = {}) {
  const root = mkdtempSync(join(tmpdir(), "geoffrey-runner-"));
  const memory = join(root, "memory-repo");
  const store = join(root, ".geoffrey");
  const fakeClaude = join(root, "fake-claude");
  const marker = join(root, "claude-called");
  mkdirSync(join(memory, "memory", "automations"), { recursive: true });
  mkdirSync(join(store, "automations"), { recursive: true });
  writeFileSync(join(store, "current-memory"), memory + "\n");
  writeFileSync(join(memory, "memory", "automations", "manifest.json"), JSON.stringify({
    schema_version: 1,
    workflows: [{
      id: "social-briefing",
      name: "Social briefing",
      purpose: "Summarize social activity",
      task: "Review connected social sources and prepare a concise briefing. PRIVATE_TASK_TOKEN",
      enabled: true,
      cadence: { times: ["08:00"], timezone: "America/Denver" },
      execution: { preference: route },
      requirements: route === "local" ? { local_paths: ["~/Documents"] } : { cloud_compatible: true },
      approval: { state: approved ? "approved" : "needs_review" },
    }],
  }));
  writeFileSync(join(store, "automations", "queue.json"), JSON.stringify({
    schema_version: 1,
    last_checked_at: "2026-10-16T12:00:00.000Z",
    items: [{
      id: "queued-one",
      workflow_id: "social-briefing",
      scheduled_for: "2026-10-16T14:00:00.000Z",
      state: "queued",
      attempt: 0,
    }],
  }));
  writeFileSync(fakeClaude, `#!/usr/bin/env bash\nprintf called > "${marker}"\nif [ "${fakeExit}" -eq 0 ]; then printf '%s\\n' '{"result":"Synthetic briefing result sk-ant-SECRET123"}'; else printf '%s\\n' 'Synthetic Claude failure Bearer secret-token' >&2; exit ${fakeExit}; fi\n`);
  chmodSync(fakeClaude, 0o755);
  return { root, memory, store, fakeClaude, marker };
}

function run(item, ...extra) {
  return spawnSync("node", [script, "--workflow", "social-briefing", ...extra], {
    env: { ...process.env, HOME: item.root, GEOFFREY_CLAUDE_BIN: item.fakeClaude },
    encoding: "utf8",
  });
}

test("approved local automation runs read-only, records history, and saves a portable result", () => {
  const item = fixture();
  try {
    const result = run(item);
    assert.equal(result.status, 0, result.stderr || result.stdout);
    const response = JSON.parse(result.stdout);
    assert.equal(response.ok, true);
    assert.equal(response.status, "succeeded");
    assert.equal(result.stdout.includes("PRIVATE_TASK_TOKEN"), false);
    const queue = JSON.parse(readFileSync(join(item.store, "automations", "queue.json"), "utf8"));
    assert.equal(queue.items.length, 0);
    const historyPath = join(item.memory, "memory", "automations", "history.json");
    const history = JSON.parse(readFileSync(historyPath, "utf8"));
    assert.equal(history.runs[0].status, "succeeded");
    assert.equal(history.runs[0].result_path, response.result_path);
    const savedResult = readFileSync(join(item.memory, response.result_path), "utf8");
    assert.match(savedResult, /Synthetic briefing result/);
    assert.equal(savedResult.includes("sk-ant-SECRET123"), false);
    assert.match(savedResult, /\[redacted credential\]/);
    assert.equal(statSync(join(item.store, "automations", "queue.json")).mode & 0o777, 0o600);
    assert.equal(statSync(historyPath).mode & 0o777, 0o600);
  } finally {
    rmSync(item.root, { recursive: true, force: true });
  }
});

test("unapproved and cloud-routed workflows are refused before Claude runs", () => {
  for (const settings of [{ approved: false, route: "local" }, { approved: true, route: "cloud" }]) {
    const item = fixture(settings);
    try {
      const result = run(item);
      assert.notEqual(result.status, 0);
      assert.equal(readFileSync(join(item.store, "automations", "queue.json"), "utf8").includes('"state":"running"'), false);
      assert.equal(spawnSync("test", ["-e", item.marker]).status, 1);
    } finally {
      rmSync(item.root, { recursive: true, force: true });
    }
  }
});

test("failed local automation remains retryable and retry succeeds", () => {
  const item = fixture({ fakeExit: 7 });
  try {
    const failure = run(item);
    assert.notEqual(failure.status, 0);
    let queue = JSON.parse(readFileSync(join(item.store, "automations", "queue.json"), "utf8"));
    assert.equal(queue.items[0].state, "failed");
    assert.equal(queue.items[0].attempt, 1);
    let history = JSON.parse(readFileSync(join(item.memory, "memory", "automations", "history.json"), "utf8"));
    assert.equal(history.runs[0].status, "failed");
    assert.equal(history.runs[0].error.includes("secret-token"), false);

    writeFileSync(item.fakeClaude, `#!/usr/bin/env bash\nprintf '%s\\n' '{"result":"Recovered briefing"}'\n`);
    chmodSync(item.fakeClaude, 0o755);
    const retry = run(item, "--retry");
    assert.equal(retry.status, 0, retry.stderr || retry.stdout);
    queue = JSON.parse(readFileSync(join(item.store, "automations", "queue.json"), "utf8"));
    assert.equal(queue.items.length, 0);
    history = JSON.parse(readFileSync(join(item.memory, "memory", "automations", "history.json"), "utf8"));
    assert.deepEqual(history.runs.map(({ status }) => status), ["failed", "succeeded"]);
    assert.equal(history.runs[1].attempt, 2);
  } finally {
    rmSync(item.root, { recursive: true, force: true });
  }
});

test("a second automation run is refused while the execution lock is held", () => {
  const item = fixture();
  try {
    writeFileSync(join(item.store, "automations", "run.lock"), "held\n");
    const result = run(item);
    assert.notEqual(result.status, 0);
    assert.match(JSON.parse(result.stdout).error, /already running/i);
    assert.equal(spawnSync("test", ["-e", item.marker]).status, 1);
  } finally {
    rmSync(item.root, { recursive: true, force: true });
  }
});
