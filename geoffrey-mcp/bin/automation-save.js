#!/usr/bin/env node

// Saves an owner-reviewed, secret-free workflow definition to private memory.
// It does not create, update, enable, or delete any local or cloud schedule.

import { chmodSync, existsSync, mkdirSync, readFileSync, renameSync, writeFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";

const args = process.argv.slice(2);
const payloadIndex = args.indexOf("--payload");
const encoded = payloadIndex >= 0 ? args[payloadIndex + 1] : "";
const home = homedir();
const store = join(home, ".geoffrey");
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

function containsCredential(value) {
  const text = String(value ?? "");
  return /-----BEGIN [^-]*PRIVATE KEY-----/i.test(text)
    || /\b(?:sk-ant-|gh[pousr]_|ya29\.)[A-Za-z0-9._-]+\b/i.test(text)
    || /\b(?:access_token|refresh_token|client_secret|api_key|password)\s*[:=]/i.test(text)
    || /\bBearer\s+[^\s"']+/i.test(text);
}

function validTimezone(value) {
  try {
    new Intl.DateTimeFormat("en-US", { timeZone: value }).format(new Date());
    return true;
  } catch {
    return false;
  }
}

function fail(message) {
  console.log(JSON.stringify({ ok: false, error: message }));
  process.exitCode = 1;
}

try {
  if (!encoded) throw new Error("Automation details were not provided.");
  let request;
  try { request = JSON.parse(Buffer.from(encoded, "base64").toString("utf8")); }
  catch { throw new Error("Automation details could not be read."); }

  const memoryRoot = existsSync(pointer) ? readFileSync(pointer, "utf8").split(/\r?\n/, 1)[0].trim() : "";
  if (!memoryRoot || !existsSync(join(memoryRoot, "memory"))) throw new Error("Private Geoffrey memory is not ready.");

  const id = cleanText(request.id, 84, "Workflow ID").toLowerCase();
  if (!/^[a-z0-9][a-z0-9._-]{2,83}$/.test(id)) throw new Error("Workflow ID contains unsupported characters.");
  const name = cleanText(request.name, 120, "Name");
  const purpose = cleanText(request.purpose, 500, "Purpose");
  const task = cleanText(request.task, 20000, "Task instructions");
  if ([name, purpose, task].some(containsCredential)) {
    throw new Error("Remove passwords, tokens, API keys, and other credentials before saving this workflow.");
  }

  const route = request.route === "cloud" ? "cloud" : request.route === "local" ? "local" : "review";
  const timezone = cleanText(request.timezone, 100, "Timezone");
  if (!validTimezone(timezone)) throw new Error("Choose a valid timezone.");
  const times = [...new Set(Array.isArray(request.times) ? request.times : [])].sort();
  if (times.length < 1 || times.length > 3 || times.some((time) => !/^(?:[01]\d|2[0-3]):[0-5]\d$/.test(time))) {
    throw new Error("Choose one to three valid daily run times.");
  }
  if (request.result_destination !== "private_memory") throw new Error("Automation results must stay in private Geoffrey memory.");

  const sourceKind = ["legacy_memory", "memory_manifest", "user_created"].includes(request.source?.kind)
    ? request.source.kind
    : "user_created";
  const sourcePath = typeof request.source?.path === "string" ? request.source.path.trim() : "";
  if (sourcePath && (sourcePath.startsWith("/") || sourcePath.split(/[\\/]/).includes(".."))) {
    throw new Error("The imported workflow path is not safe.");
  }

  const approved = request.approved === true;
  const manifestPath = join(memoryRoot, "memory", "automations", "manifest.json");
  const manifest = readJson(manifestPath, { schema_version: 1, workflows: [] });
  const workflows = Array.isArray(manifest.workflows) ? manifest.workflows : [];
  const existingIndex = workflows.findIndex((item) => item?.id === id);
  const existing = existingIndex >= 0 ? workflows[existingIndex] : {};
  const now = new Date().toISOString();
  const workflow = {
    ...existing,
    id,
    name,
    purpose,
    task,
    enabled: approved,
    cadence: { type: "daily", times, timezone },
    execution: {
      preference: route,
      deployment_state: route === "cloud" ? "not_connected" : route === "local" ? "not_applicable" : "not_connected",
      verified_at: null,
    },
    requirements: {
      capabilities: Array.isArray(existing.requirements?.capabilities) ? existing.requirements.capabilities : [],
      cloud_connections: Array.isArray(existing.requirements?.cloud_connections) ? existing.requirements.cloud_connections : [],
      local_paths: route === "local" && Array.isArray(existing.requirements?.local_paths) ? existing.requirements.local_paths : [],
      cloud_compatible: route === "cloud",
    },
    result_destination: "private_memory",
    approval: {
      state: approved ? "approved" : "needs_review",
      approved_at: approved ? now : null,
      approved_by: approved ? "owner" : null,
    },
    source: {
      kind: sourceKind,
      path: sourcePath || null,
    },
    updated_at: now,
  };
  if (existingIndex >= 0) workflows[existingIndex] = workflow;
  else workflows.push(workflow);

  mkdirSync(join(memoryRoot, "memory", "automations"), { recursive: true, mode: 0o700 });
  const temporary = manifestPath + ".tmp";
  writeFileSync(temporary, JSON.stringify({ schema_version: 1, workflows }, null, 2) + "\n", { mode: 0o600 });
  chmodSync(temporary, 0o600);
  renameSync(temporary, manifestPath);
  console.log(JSON.stringify({ ok: true, workflow_id: id, approval_state: workflow.approval.state, route }));
} catch (error) {
  fail(error?.message || "Geoffrey could not save this workflow.");
}
