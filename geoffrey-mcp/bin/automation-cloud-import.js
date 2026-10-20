#!/usr/bin/env node

// Fetches one workflow's dedicated Claude result branch and imports only
// validated result envelopes. It never checks out or merges the cloud branch.

import { spawnGit } from "../src/git-process.js";
import { chmodSync, closeSync, existsSync, mkdirSync, openSync, readFileSync, renameSync, statSync, unlinkSync, writeFileSync } from "node:fs";
import { homedir } from "node:os";
import { dirname, join } from "node:path";
import { cloudInboxPrefix, cloudResultBranch, importCloudEnvelopes } from "../src/cloud-result-inbox.js";

const args = process.argv.slice(2);
const workflowIndex = args.indexOf("--workflow");
const workflowID = workflowIndex >= 0 ? args[workflowIndex + 1] : "";
const store = join(homedir(), ".geoffrey");
const pointer = join(store, "current-memory");
const lockPath = join(store, "automations", "run.lock");

function cleanText(value, fallback = "") {
  return typeof value === "string" && value.trim() ? value.trim() : fallback;
}

function readJson(path, fallback) {
  try { return JSON.parse(readFileSync(path, "utf8")); } catch { return fallback; }
}

function atomicJson(path, value) {
  mkdirSync(dirname(path), { recursive: true, mode: 0o700 });
  const temporary = path + ".tmp";
  writeFileSync(temporary, JSON.stringify(value, null, 2) + "\n", { mode: 0o600 });
  chmodSync(temporary, 0o600);
  renameSync(temporary, path);
}

function git(memoryRoot, parameters, options = {}) {
  return spawnGit(["-C", memoryRoot, ...parameters], {
    encoding: "utf8",
    timeout: options.timeout ?? 60_000,
    maxBuffer: options.maxBuffer ?? 2 * 1024 * 1024,
    stdio: ["ignore", "pipe", "pipe"],
  });
}

function acquireLock() {
  mkdirSync(dirname(lockPath), { recursive: true, mode: 0o700 });
  if (existsSync(lockPath)) {
    try {
      if (Date.now() - statSync(lockPath).mtimeMs > 20 * 60 * 1000) unlinkSync(lockPath);
    } catch { /* The exclusive open below remains the authority. */ }
  }
  try { return openSync(lockPath, "wx", 0o600); }
  catch { throw new Error("Another Geoffrey automation is already running."); }
}

function fail(message) {
  console.log(JSON.stringify({ ok: false, error: cleanText(message, "Geoffrey could not import cloud results.").slice(0, 500) }));
  process.exitCode = 1;
}

let lock;
try {
  if (!workflowID) throw new Error("Choose a cloud automation to check.");
  const memoryRoot = existsSync(pointer) ? readFileSync(pointer, "utf8").split(/\r?\n/, 1)[0].trim() : "";
  if (!memoryRoot || !existsSync(join(memoryRoot, "memory"))) throw new Error("Private Geoffrey memory is not ready.");
  if (!existsSync(join(memoryRoot, ".git"))) throw new Error("Private Geoffrey memory is not connected to Git.");

  const manifestPath = join(memoryRoot, "memory", "automations", "manifest.json");
  const manifest = readJson(manifestPath, { workflows: [] });
  const workflow = (Array.isArray(manifest.workflows) ? manifest.workflows : []).find((item) => item?.id === workflowID);
  if (!workflow) throw new Error("Automation not found in private memory.");
  if (!cleanText(workflow.execution?.routine_url)) throw new Error("Connect and review this Claude Routine before checking results.");
  if (workflow.enabled !== true || workflow.approval?.state !== "approved"
      || workflow.execution?.preference !== "cloud" || workflow.requirements?.cloud_compatible !== true) {
    throw new Error("This workflow is not approved for Claude cloud results.");
  }
  const branch = cloudResultBranch(workflow.id);

  lock = acquireLock();
  const remote = git(memoryRoot, ["remote", "get-url", "origin"]);
  if (remote.status !== 0) throw new Error("Private memory GitHub sync is not configured.");

  const ref = `refs/remotes/origin/${branch}`;
  const fetch = git(memoryRoot, ["fetch", "--no-tags", "origin", `+refs/heads/${branch}:${ref}`], { timeout: 90_000 });
  if (fetch.status !== 0) {
    const detail = cleanText(fetch.stderr || fetch.stdout);
    if (/couldn['’]t find remote ref|remote ref does not exist/i.test(detail)) {
      console.log(JSON.stringify({ ok: true, workflow_id: workflow.id, branch, branch_exists: false, imported: 0, already_imported: 0, rejected: 0 }));
      process.exitCode = 0;
    } else {
      throw new Error("Geoffrey could not securely fetch the cloud result branch. Check GitHub access and try again.");
    }
  } else {
    const prefix = cloudInboxPrefix(workflow.id);
    const listing = git(memoryRoot, ["ls-tree", "-r", "-z", "--name-only", ref, "--", prefix]);
    if (listing.status !== 0) throw new Error("Geoffrey could not inspect the cloud result branch.");
    const paths = listing.stdout.split("\0").filter(Boolean)
      .filter((path) => path.startsWith(prefix + "/") && !path.slice(prefix.length + 1).includes("/") && /^[A-Za-z0-9._-]+\.json$/.test(path.slice(prefix.length + 1)))
      .sort()
      .slice(-100);
    const candidates = [];
    const parseRejected = [];
    for (const path of paths) {
      const shown = git(memoryRoot, ["show", `${ref}:${path}`], { maxBuffer: 400_000 });
      if (shown.status !== 0 || Buffer.byteLength(shown.stdout, "utf8") > 300_000) {
        parseRejected.push({ path, error: "Envelope could not be read within the safety limit." });
        continue;
      }
      try { candidates.push({ path, value: JSON.parse(shown.stdout) }); }
      catch { parseRejected.push({ path, error: "Envelope is not valid JSON." }); }
    }

    const portableHistoryPath = join(memoryRoot, "memory", "automations", "history.json");
    const localHistoryPath = join(store, "automations", "history.json");
    const history = readJson(portableHistoryPath, readJson(localHistoryPath, { schema_version: 1, runs: [] }));
    const imported = importCloudEnvelopes({ memoryRoot, workflow, branch, candidates, history, portableHistoryPath });
    const rejected = [...parseRejected, ...imported.rejected];
    if (imported.imported.length) atomicJson(localHistoryPath, readJson(portableHistoryPath, { schema_version: 1, runs: [] }));
    console.log(JSON.stringify({
      ok: true,
      workflow_id: workflow.id,
      branch,
      branch_exists: true,
      imported: imported.imported.length,
      already_imported: imported.alreadyImported,
      rejected: rejected.length,
      rejected_details: rejected.slice(0, 5),
      latest_result_path: [...imported.imported].reverse().find((item) => item.result_path)?.result_path ?? null,
    }));
  }
} catch (error) {
  fail(error?.message);
} finally {
  if (lock !== undefined) {
    try { closeSync(lock); } catch { /* Already closed. */ }
    try { unlinkSync(lockPath); } catch { /* Nothing to remove. */ }
  }
}
