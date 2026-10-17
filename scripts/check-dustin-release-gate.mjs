#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { spawnSync } from "node:child_process";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const args = process.argv.slice(2);
const reportOnly = args.includes("--report-only");
const evidenceIndex = args.indexOf("--evidence");
if (evidenceIndex >= 0 && !args[evidenceIndex + 1]) {
  console.error("Usage: check-dustin-release-gate.mjs [--report-only] [--evidence PATH]");
  process.exit(64);
}

const evidencePath = path.resolve(
  evidenceIndex >= 0
    ? args[evidenceIndex + 1]
    : process.env.GEOFFREY_DUSTIN_RELEASE_EVIDENCE || path.join(root, ".release-evidence/dustin-gate.json")
);

const requiredGates = [
  ["local_verification", "Complete local verification for the exact release commit"],
  ["clean_mac_install", "Install and launch on a clean Mac without a development environment"],
  ["gatekeeper_notarization", "Verify Developer ID signing, notarization, stapling, and Gatekeeper acceptance"],
  ["existing_state_migration", "Back up, discover, and use the existing owner state without recreating it"],
  ["claude_context", "Preserve context across at least two Claude conversation turns"],
  ["multi_account_connections", "Connect, distinguish, and test the pilot Gmail and Outlook accounts"],
  ["social_briefing_cadence", "Import and run the existing three-times-daily social briefing"],
  ["off_mac_cloud_run", "Prove cloud-capable work runs while the Mac is off, or records the approved fallback"],
  ["github_sync_restore", "Prove GitHub sync success, visible failure, and non-secret restore"],
  ["credential_safety", "Verify credentials are absent from GitHub, logs, manifests, and release archives"],
  ["signed_update_rollback", "Install a signed update while preserving state and prove rollback"],
  ["no_terminal_acceptance", "Record that the owner completed the main workflow without Terminal help"],
];

let blocked = 0;
function pass(id, detail) {
  console.log(`gate=${id} status=passed detail=${JSON.stringify(detail)}`);
}
function block(id, detail) {
  blocked += 1;
  console.log(`gate=${id} status=blocked detail=${JSON.stringify(detail)}`);
}
function run(command, commandArgs) {
  return spawnSync(command, commandArgs, { cwd: root, encoding: "utf8" });
}

const headResult = run("git", ["rev-parse", "HEAD"]);
const head = headResult.status === 0 ? headResult.stdout.trim() : "";
if (head) pass("source_commit", head);
else block("source_commit", "The release commit could not be resolved.");

const statusResult = run("git", ["status", "--porcelain", "--untracked-files=all"]);
if (statusResult.status === 0 && statusResult.stdout.trim() === "") {
  pass("source_tree", "The release commit has no uncommitted changes.");
} else {
  block("source_tree", "Commit or remove every source change before recording release evidence.");
}

const historyResult = run(path.join(root, "scripts/audit-history-exposure.sh"), ["--report-only"]);
const historyOutput = historyResult.stdout.trim();
if (historyOutput) console.log(historyOutput);
if (historyResult.status === 0 && /(^|\n)status=clean(\n|$)/.test(historyOutput)) {
  pass("history_remediation", "No audited recipient media, private app archives, or credential-named paths remain reachable.");
} else {
  block("history_remediation", "The historical-exposure audit must report status=clean after coordinated remediation.");
}

let evidence;
try {
  evidence = JSON.parse(fs.readFileSync(evidencePath, "utf8"));
  pass("evidence_file", evidencePath);
} catch (error) {
  block("evidence_file", `Create owner-reviewed evidence from docs/dustin-release-evidence.example.json at ${evidencePath}.`);
}

if (evidence) {
  if (evidence.schema_version === 1) pass("evidence_schema", "schema_version=1");
  else block("evidence_schema", "The evidence file must use schema_version 1.");

  if (head && evidence.release_commit === head) pass("evidence_commit", head);
  else block("evidence_commit", "release_commit must exactly match the current Git commit.");

  if (typeof evidence.recorded_at === "string" && !Number.isNaN(Date.parse(evidence.recorded_at))) {
    pass("evidence_timestamp", evidence.recorded_at);
  } else {
    block("evidence_timestamp", "recorded_at must be an ISO-8601 timestamp.");
  }

  if (typeof evidence.reviewer === "string" && evidence.reviewer.trim()) {
    pass("evidence_reviewer", evidence.reviewer.trim());
  } else {
    block("evidence_reviewer", "Name the person who reviewed the evidence.");
  }
}

for (const [id, description] of requiredGates) {
  const gate = evidence?.gates?.[id];
  const references = Array.isArray(gate?.evidence)
    ? gate.evidence.filter((item) => typeof item === "string" && item.trim())
    : [];
  if (gate?.status === "passed" && references.length > 0) {
    pass(id, `${description}. Evidence: ${references.join("; ")}`);
  } else {
    block(id, `${description}. Requires status=passed and at least one non-secret evidence reference.`);
  }
}

console.log(`evidence_file=${evidencePath}`);
console.log(`blocked_checks=${blocked}`);
console.log(`dustin_release_gate=${blocked === 0 ? "passed" : "blocked"}`);

if (blocked > 0 && !reportOnly) process.exit(2);
