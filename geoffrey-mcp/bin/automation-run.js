#!/usr/bin/env node

import { closeSync, existsSync, mkdirSync, openSync, readFileSync, statSync, unlinkSync } from "node:fs";
import { homedir } from "node:os";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { loadAutomationRunState, runLocalAutomation } from "../src/automation-runner.js";

const args = process.argv.slice(2);
const workflowIndex = args.indexOf("--workflow");
const workflowID = workflowIndex >= 0 ? args[workflowIndex + 1] : "";
const retry = args.includes("--retry");
const runNow = args.includes("--now");
const home = homedir();
const store = join(home, ".geoffrey");
const pointer = join(store, "current-memory");
const memoryRoot = existsSync(pointer) ? readFileSync(pointer, "utf8").split(/\r?\n/, 1)[0].trim() : "";
const manifestCandidates = [
  memoryRoot && join(memoryRoot, "memory", "automations", "manifest.json"),
  memoryRoot && join(memoryRoot, "automations", "manifest.json"),
  join(store, "automations", "manifest.json"),
].filter(Boolean);
const manifestPath = manifestCandidates.find((path) => existsSync(path));
const queuePath = join(store, "automations", "queue.json");
const localHistoryPath = join(store, "automations", "history.json");
const portableHistoryPath = memoryRoot && join(memoryRoot, "memory", "automations", "history.json");
const lockPath = join(store, "automations", "run.lock");

function readJson(path, fallback) {
  try { return JSON.parse(readFileSync(path, "utf8")); } catch { return fallback; }
}

function fail(message) {
  console.log(JSON.stringify({ ok: false, error: message }));
  process.exitCode = 1;
}

function acquireLock() {
  mkdirSync(dirname(lockPath), { recursive: true, mode: 0o700 });
  if (existsSync(lockPath)) {
    try {
      if (Date.now() - statSync(lockPath).mtimeMs > 20 * 60 * 1000) unlinkSync(lockPath);
    } catch { /* The exclusive open below remains the authority. */ }
  }
  try {
    return openSync(lockPath, "wx", 0o600);
  } catch {
    throw new Error("Another Geoffrey automation is already running.");
  }
}

if (!workflowID) {
  fail("Choose an automation to run.");
} else if (!manifestPath || !portableHistoryPath) {
  fail("Automation memory is not ready.");
} else {
  let lock;
  try {
    lock = acquireLock();
    const { queue, history } = loadAutomationRunState({ queuePath, localHistoryPath, portableHistoryPath });
    const result = runLocalAutomation({
      workflowID,
      manifest: readJson(manifestPath, { workflows: [] }),
      queue,
      history,
      memoryRoot,
      queuePath,
      localHistoryPath,
      portableHistoryPath,
      claudeBin: process.env.GEOFFREY_CLAUDE_BIN || "claude",
      retry,
      runNow,
    });
    console.log(JSON.stringify({
      ok: result.ok,
      workflow_id: workflowID,
      run_id: result.run.id,
      status: result.run.status,
      result_path: result.run.result_path,
      error: result.run.error,
    }));
    if (!result.ok) process.exitCode = 1;
  } catch (error) {
    fail(error?.message || "Geoffrey could not run this automation.");
  } finally {
    if (lock !== undefined) {
      try { closeSync(lock); } catch { /* Already closed. */ }
      try { unlinkSync(lockPath); } catch { /* Nothing to remove. */ }
    }
  }
}
