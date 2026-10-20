#!/usr/bin/env node

// Records a non-secret Claude Routine reference and explicit owner review.
// It never creates, updates, enables, pauses, runs, or deletes a cloud routine.

import { chmodSync, existsSync, mkdirSync, readFileSync, renameSync, writeFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";

const args = process.argv.slice(2);
const payloadIndex = args.indexOf("--payload");
const encoded = payloadIndex >= 0 ? args[payloadIndex + 1] : "";
const store = join(homedir(), ".geoffrey");
const pointer = join(store, "current-memory");

function readJson(path, fallback) {
  try { return JSON.parse(readFileSync(path, "utf8")); } catch { return fallback; }
}

function cleanText(value, maximum, label) {
  const text = typeof value === "string" ? value.trim() : "";
  if (!text) throw new Error(`${label} is required.`);
  if (text.length > maximum) throw new Error(`${label} is too long.`);
  return text;
}

function claudeURL(value, kind) {
  const text = cleanText(value, 500, kind === "routine" ? "Claude Routine link" : "Claude run link");
  let url;
  try { url = new URL(text); } catch { throw new Error(`Paste a valid Claude ${kind} link.`); }
  if (url.protocol !== "https:" || url.hostname !== "claude.ai" || url.username || url.password || url.search || url.hash) {
    throw new Error(`Paste a clean https://claude.ai ${kind} link without credentials or tracking details.`);
  }
  const isSession = /^\/code\/session_[A-Za-z0-9_-]+\/?$/.test(url.pathname);
  if (kind === "run" && !isSession) throw new Error("Paste the Claude session link for the reviewed test run.");
  const isScheduledTask = /^\/scheduled-task\/trig_[A-Za-z0-9_-]+\/?$/.test(url.pathname);
  const isRoutine = /^\/code\/routines\/[^/]+\/?$/.test(url.pathname);
  if (kind === "routine" && !isScheduledTask && !isRoutine) {
    throw new Error("Paste the Claude Routine detail link, not a run session link.");
  }
  return url.toString();
}

function fail(message) {
  console.log(JSON.stringify({ ok: false, error: message }));
  process.exitCode = 1;
}

try {
  if (!encoded) throw new Error("Cloud connection details were not provided.");
  let request;
  try { request = JSON.parse(Buffer.from(encoded, "base64").toString("utf8")); }
  catch { throw new Error("Cloud connection details could not be read."); }

  const memoryRoot = existsSync(pointer) ? readFileSync(pointer, "utf8").split(/\r?\n/, 1)[0].trim() : "";
  if (!memoryRoot || !existsSync(join(memoryRoot, "memory"))) throw new Error("Private Geoffrey memory is not ready.");

  const workflowID = cleanText(request.workflow_id, 84, "Workflow ID").toLowerCase();
  const routineURL = claudeURL(request.routine_url, "routine");
  const additionalRoutineURLs = [...new Set((Array.isArray(request.additional_routine_urls) ? request.additional_routine_urls : []).map(value => claudeURL(value, "routine")))].filter(value => value !== routineURL);
  if (additionalRoutineURLs.length > 2) throw new Error("Record no more than three cloud task links.");
  if (request.connectors_reviewed !== true) throw new Error("Review the routine's included connectors before recording the connection.");
  if (request.schedule_confirmed !== true) throw new Error("Confirm that Claude shows the approved schedule before recording the connection.");

  const runText = typeof request.run_url === "string" ? request.run_url.trim() : "";
  const runURL = runText ? claudeURL(runText, "run") : null;
  if (request.run_reviewed === true && !runURL) throw new Error("Paste the successful run session link you reviewed.");
  if (runURL && request.run_reviewed !== true) throw new Error("Confirm that you reviewed the test run before marking this routine active.");

  const manifestPath = join(memoryRoot, "memory", "automations", "manifest.json");
  const manifest = readJson(manifestPath, { schema_version: 1, workflows: [] });
  const workflows = Array.isArray(manifest.workflows) ? manifest.workflows : [];
  const index = workflows.findIndex((item) => item?.id === workflowID);
  if (index < 0) throw new Error("Save and approve this workflow in Geoffrey before connecting it to Claude cloud.");
  const workflow = workflows[index];
  if (workflow.enabled !== true || workflow.approval?.state !== "approved") {
    throw new Error("Approve this workflow in Geoffrey before connecting it to Claude cloud.");
  }
  if (workflow.execution?.preference !== "cloud" || workflow.requirements?.cloud_compatible !== true) {
    throw new Error("Only an approved cloud-capable workflow can be linked to a Claude Routine.");
  }

  const now = new Date().toISOString();
  const active = Boolean(runURL && request.run_reviewed === true);
  workflows[index] = {
    ...workflow,
    execution: {
      ...workflow.execution,
      routine_url: routineURL,
      additional_routine_urls: additionalRoutineURLs,
      deployment_state: active ? "active" : "connected",
      verified_at: active ? now : null,
      verification: {
        method: active ? "owner_reviewed_run" : "owner_setup_review",
        connected_at: workflow.execution?.verification?.connected_at || now,
        owner_confirmed_at: now,
        run_url: runURL,
      },
    },
    updated_at: now,
  };

  mkdirSync(join(memoryRoot, "memory", "automations"), { recursive: true, mode: 0o700 });
  const temporary = manifestPath + ".tmp";
  writeFileSync(temporary, JSON.stringify({ ...manifest, schema_version: 1, workflows }, null, 2) + "\n", { mode: 0o600 });
  chmodSync(temporary, 0o600);
  renameSync(temporary, manifestPath);
  console.log(JSON.stringify({
    ok: true,
    workflow_id: workflowID,
    deployment_state: active ? "active" : "connected",
    verified_at: active ? now : null,
  }));
} catch (error) {
  fail(error?.message || "Geoffrey could not record this Claude Routine connection.");
}
