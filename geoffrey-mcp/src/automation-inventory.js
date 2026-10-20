import { createHash } from "node:crypto";
import { basename, extname } from "node:path";
import { cloudResultBranch } from "./cloud-result-inbox.js";

const ROUTES = new Set(["cloud", "local", "review"]);

export function isAutomationCandidatePath(path) {
  if (typeof path !== "string" || !path.trim()) return false;
  const normalized = path.replaceAll("\\", "/");
  if (/(^|\/)(briefings|results|cloud-inbox)(\/|$)/i.test(normalized)) return false;
  if (/^(briefing[-_](reactions|feedback)|priority[-_]feedback|completed[-_]items|history|manifest|queue)\.(json|md)$/i.test(basename(normalized))) return false;
  return /(automat|routine|schedule|brief)/i.test(basename(normalized));
}

function cleanText(value, fallback = "") {
  return typeof value === "string" && value.trim() ? value.trim() : fallback;
}

function cleanList(value) {
  return Array.isArray(value)
    ? value.filter((item) => typeof item === "string" && item.trim()).map((item) => item.trim())
    : [];
}

function stableID(value) {
  return createHash("sha256").update(value).digest("hex").slice(0, 12);
}

function titleFromPath(path) {
  const file = basename(path, extname(path));
  return file
    .replace(/[_-]+/g, " ")
    .replace(/\b\w/g, (letter) => letter.toUpperCase())
    .trim() || "Imported workflow";
}

function scheduleSummary(cadence = {}) {
  if (cleanText(cadence.summary)) return cleanText(cadence.summary);
  if (cleanText(cadence.cron)) return `Cron: ${cleanText(cadence.cron)}`;
  if (Array.isArray(cadence.times) && cadence.times.length) {
    return `Daily at ${cadence.times.map((time) => cleanText(time)).filter(Boolean).join(", ")}`;
  }
  return "Schedule needs review";
}

export function classifyExecution(workflow, readyCapabilities = new Set()) {
  const execution = workflow.execution ?? {};
  const requirements = workflow.requirements ?? {};
  const declaredRoute = cleanText(execution.route);
  const preference = cleanText(execution.preference, "auto");
  const localPaths = cleanList(requirements.local_paths);
  const capabilities = cleanList(requirements.capabilities);
  const missing = capabilities.filter((capability) => !readyCapabilities.has(capability));

  if (localPaths.length || preference === "local") {
    return {
      route: "local",
      reason: localPaths.length
        ? "This workflow needs files or tools on this Mac. Missed runs can be queued for the next time Geoffrey opens."
        : "This workflow is set to run on this Mac. Missed runs can be queued for the next time Geoffrey opens.",
      missing_capabilities: missing,
    };
  }

  if (missing.length) {
    return {
      route: "review",
      reason: `Review the missing connection${missing.length === 1 ? "" : "s"} before choosing where this runs.`,
      missing_capabilities: missing,
    };
  }

  const cloudCompatible = requirements.cloud_compatible === true;
  if ((preference === "cloud" || preference === "auto") && cloudCompatible) {
    return {
      route: "cloud",
      reason: "This workflow has no declared Mac-only dependency and can be connected to a Claude cloud schedule.",
      missing_capabilities: [],
    };
  }

  if (ROUTES.has(declaredRoute) && declaredRoute !== "cloud") {
    return {
      route: declaredRoute,
      reason: cleanText(execution.reason, "Review this workflow before enabling it."),
      missing_capabilities: [],
    };
  }

  return {
    route: "review",
    reason: "Geoffrey needs the workflow's schedule and dependencies reviewed before it can run safely.",
    missing_capabilities: [],
  };
}

function normalizeWorkflow(raw, index, readyCapabilities, queueStats, latestRuns) {
  const id = cleanText(raw.id, `workflow-${index + 1}`);
  const classification = classifyExecution(raw, readyCapabilities);
  const approvalState = cleanText(raw.approval?.state, "needs_review");
  const preference = cleanText(raw.execution?.preference, "auto");
  const declaredDeploymentState = cleanText(raw.execution?.deployment_state, "not_connected");
  const verifiedAt = cleanText(raw.execution?.verified_at);
  const deploymentState = declaredDeploymentState === "active" && !verifiedAt ? "needs_verification" : declaredDeploymentState;
  const routineURL = cleanText(raw.execution?.routine_url);
  const verificationMethod = cleanText(raw.execution?.verification?.method);
  const verificationRunURL = cleanText(raw.execution?.verification?.run_url);
  const enabled = raw.enabled === true && approvalState === "approved";
  const stats = queueStats.get(id) ?? { queued: 0, failed: 0, running: 0 };
  const latestRun = latestRuns.get(id);
  const canRun = enabled && classification.route === "local" && Boolean(cleanText(raw.task));
  const state = !enabled ? "needs_review"
    : classification.route === "cloud" && deploymentState !== "active" ? deploymentState
    : stats.running ? "running"
      : stats.failed ? "failed"
        : cleanText(raw.status?.state, "ready");

  return {
    id,
    name: cleanText(raw.name, "Untitled workflow"),
    purpose: cleanText(raw.purpose, "Recurring work to review with Geoffrey."),
    task: cleanText(raw.task) || null,
    enabled,
    cadence: {
      summary: scheduleSummary(raw.cadence),
      timezone: cleanText(raw.cadence?.timezone) || null,
      times: cleanList(raw.cadence?.times),
    },
    execution: {
      route: classification.route,
      preference,
      reason: classification.route === "cloud" && deploymentState === "not_connected"
        ? "Not scheduled yet. Connect this workflow to a Claude cloud task before these times can run."
        : classification.route === "cloud" && deploymentState === "needs_update"
          ? "The saved instructions or schedule changed. Update the connected Claude task; it still uses its previous configuration until you do."
          : classification.reason,
      deployment_state: deploymentState,
      verified_at: verifiedAt || null,
      routine_url: routineURL || null,
      additional_routine_urls: cleanList(raw.execution?.additional_routine_urls),
      result_branch: classification.route === "cloud" && /^[a-z0-9][a-z0-9._-]{2,83}$/.test(id)
        ? cloudResultBranch(id)
        : null,
      verification_method: verificationMethod || null,
      verification_run_url: verificationRunURL || null,
      missing_capabilities: classification.missing_capabilities,
      can_run: canRun,
    },
    approval: {
      state: approvalState,
      approved_at: cleanText(raw.approval?.approved_at) || null,
    },
    source: {
      kind: cleanText(raw.source?.kind, "memory_manifest"),
      path: cleanText(raw.source?.path) || null,
    },
    result_destination: cleanText(raw.result_destination, "private_memory"),
    status: {
      state,
      last_run_at: cleanText(latestRun?.finished_at ?? raw.status?.last_run_at) || null,
      last_run_status: cleanText(latestRun?.status) || null,
      next_run_at: cleanText(raw.status?.next_run_at) || null,
      queued_runs: stats.queued,
      failed_runs: stats.failed,
      last_result_path: cleanText(latestRun?.result_path) || null,
      last_error: cleanText(latestRun?.error ?? raw.status?.last_error) || null,
    },
  };
}

function migratedWorkflow(path) {
  return {
    id: `imported-${stableID(path)}`,
    name: titleFromPath(path),
    purpose: "Imported from existing Geoffrey memory. Review it before enabling or changing its schedule.",
    enabled: false,
    cadence: { summary: "Schedule needs review" },
    execution: { preference: "auto", deployment_state: "not_connected" },
    requirements: { capabilities: [], local_paths: [], cloud_compatible: false },
    approval: { state: "needs_review" },
    source: { kind: "legacy_memory", path },
    status: { state: "needs_review" },
  };
}

export function buildAutomationInventory({ manifest, migration, queue, history, capabilities, sourcePath = null }) {
  const readyCapabilities = new Set(
    (Array.isArray(capabilities) ? capabilities : [])
      .filter((item) => item?.state === "ready" || item?.enabled === true)
      .flatMap((item) => [cleanText(item.id), cleanText(item.name)])
      .filter(Boolean),
  );
  const queueStats = new Map();
  for (const item of Array.isArray(queue?.items) ? queue.items : []) {
    const workflowID = cleanText(item?.workflow_id);
    if (!workflowID) continue;
    const stats = queueStats.get(workflowID) ?? { queued: 0, failed: 0, running: 0 };
    if (item.state === "failed") stats.failed += 1;
    else if (item.state === "running") stats.running += 1;
    else if (!item.state || item.state === "queued") stats.queued += 1;
    queueStats.set(workflowID, stats);
  }
  const latestRuns = new Map();
  for (const run of Array.isArray(history?.runs) ? history.runs : []) {
    const workflowID = cleanText(run?.workflow_id);
    if (workflowID) latestRuns.set(workflowID, run);
  }

  const declared = Array.isArray(manifest?.workflows) ? manifest.workflows : [];
  const removed = Array.isArray(manifest?.removed_workflows) ? manifest.removed_workflows : [];
  const removedIDs = new Set(removed.map(item => item.id));
  const removedPaths = new Set(removed.map(item => item.source?.path).filter(Boolean));
  const knownPaths = new Set(declared.map((item) => cleanText(item?.source?.path)).filter(Boolean));
  const candidates = Array.isArray(migration?.private_state?.memory_repository?.automation_candidates)
    ? migration.private_state.memory_repository.automation_candidates
    : [];
  const imported = candidates
    .filter((path) => isAutomationCandidatePath(path) && !knownPaths.has(path.trim()) && !removedPaths.has(path.trim()))
    .map((path) => migratedWorkflow(path.trim()));
  const workflows = [...declared, ...imported].filter(item => !removedIDs.has(item.id))
    .map((item, index) => normalizeWorkflow(item, index, readyCapabilities, queueStats, latestRuns))
    .sort((a, b) => a.name.localeCompare(b.name));

  return {
    schema_version: 1,
    execution_available: workflows.some((item) => item.execution.can_run),
    source: sourcePath,
    workflows,
    summary: {
      total: workflows.length,
      cloud: workflows.filter((item) => item.execution.route === "cloud").length,
      local: workflows.filter((item) => item.execution.route === "local").length,
      needs_review: workflows.filter((item) => item.execution.route === "review" || item.approval.state !== "approved").length,
      queued_runs: workflows.reduce((sum, item) => sum + item.status.queued_runs, 0),
      failed_runs: workflows.reduce((sum, item) => sum + item.status.failed_runs, 0),
    },
  };
}

function localClock(date, timezone) {
  try {
    const parts = new Intl.DateTimeFormat("en-US", {
      timeZone: timezone,
      weekday: "short",
      hour: "2-digit",
      minute: "2-digit",
      hourCycle: "h23",
    }).formatToParts(date);
    const value = Object.fromEntries(parts.map((part) => [part.type, part.value]));
    return { time: `${value.hour}:${value.minute}`, day: value.weekday.toLowerCase() };
  } catch {
    return null;
  }
}

export function queueMissedLocalRuns({ manifest, queue, capabilities, now = new Date() }) {
  const readyCapabilities = new Set(
    (Array.isArray(capabilities) ? capabilities : [])
      .filter((item) => item?.state === "ready" || item?.enabled === true)
      .flatMap((item) => [cleanText(item.id), cleanText(item.name)])
      .filter(Boolean),
  );
  const previousItems = Array.isArray(queue?.items) ? queue.items.filter((item) => item && typeof item === "object") : [];
  const existing = new Set(previousItems.map((item) => `${item.workflow_id}|${item.scheduled_for}`));
  const rawLastChecked = Date.parse(cleanText(queue?.last_checked_at));
  const nowMs = now.getTime();
  const sevenDays = 7 * 24 * 60 * 60 * 1000;
  const startMs = Number.isFinite(rawLastChecked) ? Math.max(rawLastChecked, nowMs - sevenDays) : nowMs;
  const workflows = Array.isArray(manifest?.workflows) ? manifest.workflows : [];
  const additions = [];

  for (const workflow of workflows) {
    if (workflow?.enabled !== true || workflow?.approval?.state !== "approved") continue;
    if (classifyExecution(workflow, readyCapabilities).route !== "local") continue;
    const timezone = cleanText(workflow?.cadence?.timezone);
    const times = new Set(cleanList(workflow?.cadence?.times));
    const days = new Set(cleanList(workflow?.cadence?.days).map((day) => day.slice(0, 3).toLowerCase()));
    if (!timezone || !times.size) continue;
    let workflowCount = 0;
    const firstMinute = Math.floor(startMs / 60000) * 60000 + 60000;
    for (let timestamp = firstMinute; timestamp <= nowMs && workflowCount < 10 && additions.length < 50; timestamp += 60000) {
      const clock = localClock(new Date(timestamp), timezone);
      if (!clock || !times.has(clock.time) || (days.size && !days.has(clock.day))) continue;
      const scheduledFor = new Date(timestamp).toISOString();
      const key = `${workflow.id}|${scheduledFor}`;
      if (existing.has(key)) continue;
      additions.push({
        id: `queued-${stableID(key)}`,
        workflow_id: workflow.id,
        scheduled_for: scheduledFor,
        state: "queued",
        reason: "missed_while_unavailable",
        created_at: now.toISOString(),
      });
      existing.add(key);
      workflowCount += 1;
    }
  }

  return {
    schema_version: 1,
    last_checked_at: now.toISOString(),
    items: [...previousItems, ...additions],
    added: additions.length,
  };
}
