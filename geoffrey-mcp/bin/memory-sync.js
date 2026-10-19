#!/usr/bin/env node

// Machine-readable private-memory synchronization for Geoffrey.app.
// Diverged histories are rebased only when Git can do so cleanly. A conflict
// is aborted immediately, leaving the owner's local branch and files intact.

import { spawnSync } from "node:child_process";
import { chmodSync, existsSync, lstatSync, mkdirSync, readFileSync, renameSync, writeFileSync } from "node:fs";
import { homedir } from "node:os";
import { basename, dirname, join, resolve, sep } from "node:path";

const args = process.argv.slice(2);
const statusOnly = args.includes("--status");
const phaseIndex = args.indexOf("--phase");
const phase = phaseIndex >= 0 && args[phaseIndex + 1] ? args[phaseIndex + 1].slice(0, 120) : "Geoffrey app change";
const store = join(homedir(), ".geoffrey");
const pointer = join(store, "current-memory");
const statusPath = join(store, "memory-sync.json");

function cleanText(value, fallback = "") {
  return typeof value === "string" && value.trim() ? value.trim() : fallback;
}

function git(memoryRoot, parameters, options = {}) {
  return spawnSync(process.env.GEOFFREY_GIT_BIN || "git", ["-C", memoryRoot, ...parameters], {
    encoding: "utf8",
    timeout: options.timeout ?? 60_000,
    maxBuffer: options.maxBuffer ?? 2 * 1024 * 1024,
    stdio: ["ignore", "pipe", "pipe"],
  });
}

function value(memoryRoot, parameters) {
  const result = git(memoryRoot, parameters);
  return result.status === 0 ? cleanText(result.stdout) : "";
}

function atomicJson(path, object) {
  mkdirSync(dirname(path), { recursive: true, mode: 0o700 });
  const temporary = path + ".tmp";
  writeFileSync(temporary, JSON.stringify(object, null, 2) + "\n", { mode: 0o600 });
  chmodSync(temporary, 0o600);
  renameSync(temporary, path);
}

function credentialReason(path, content) {
  const name = basename(path).toLowerCase();
  if (name === ".env" || name === "accounts.json" || name === "credentials.json"
      || /\.(?:pem|key|p12|pfx|token|secret)$/.test(name)) {
    return "a credential-bearing filename";
  }
  if (/-----BEGIN [^-]*PRIVATE KEY-----/i.test(content)) return "a private key";
  if (/\b(?:sk-ant-|gh[pousr]_|ya29\.)[A-Za-z0-9._-]+\b/i.test(content)) return "an access token";
  if (/\bBearer\s+[A-Za-z0-9._~+/-]{12,}/i.test(content)) return "a bearer credential";
  if (/\b(?:access_token|refresh_token|client_secret|api_key|password)\s*[:=]\s*["']?[^\s"']+/i.test(content)) {
    return "a named credential";
  }
  return null;
}

function changedPaths(memoryRoot) {
  const working = git(memoryRoot, ["ls-files", "--modified", "--others", "--exclude-standard", "-z"]);
  const staged = git(memoryRoot, ["diff", "--cached", "--name-only", "-z"]);
  const paths = new Set();
  for (const output of [working.status === 0 ? working.stdout : "", staged.status === 0 ? staged.stdout : ""]) {
    for (const path of output.split("\0").filter(Boolean)) paths.add(path);
  }
  return { paths: [...paths], staged: new Set((staged.status === 0 ? staged.stdout : "").split("\0").filter(Boolean)) };
}

function findCredentialRisk(memoryRoot) {
  const root = resolve(memoryRoot) + sep;
  const changes = changedPaths(memoryRoot);
  for (const relativePath of changes.paths) {
    const path = resolve(memoryRoot, relativePath);
    if (!path.startsWith(root)) return { path: relativePath, reason: "a path outside private memory" };
    let content = "";
    let hasWorkingFile = false;
    try {
      if (existsSync(path) && lstatSync(path).isFile()) {
        hasWorkingFile = true;
        const file = readFileSync(path);
        if (file.length > 5 * 1024 * 1024) return { path: relativePath, reason: "a file too large for Geoffrey's credential check" };
        content = file.toString("utf8");
      } else if (existsSync(path) && lstatSync(path).isSymbolicLink()) {
        return { path: relativePath, reason: "a symbolic link" };
      }
    } catch {
      return { path: relativePath, reason: "a file Geoffrey could not inspect safely" };
    }
    if (hasWorkingFile) {
      const workingReason = credentialReason(relativePath, content);
      if (workingReason) return { path: relativePath, reason: workingReason };
    }
    if (changes.staged.has(relativePath)) {
      const staged = git(memoryRoot, ["show", `:${relativePath}`]);
      if (staged.status === 0) {
        const stagedReason = credentialReason(relativePath, staged.stdout);
        if (stagedReason) return { path: relativePath, reason: stagedReason };
      }
    }
  }
  return null;
}

function findOutgoingCredentialRisk(memoryRoot, remoteRef = null) {
  const listed = remoteRef
    ? git(memoryRoot, ["diff", "--name-only", "-z", `${remoteRef}...HEAD`])
    : git(memoryRoot, ["ls-tree", "-r", "-z", "--name-only", "HEAD"]);
  if (listed.status !== 0) return { path: "private memory", reason: "outgoing changes Geoffrey could not inspect safely" };
  for (const relativePath of listed.stdout.split("\0").filter(Boolean)) {
    const existsAtHead = git(memoryRoot, ["cat-file", "-e", `HEAD:${relativePath}`]).status === 0;
    if (!existsAtHead) continue;
    const tree = git(memoryRoot, ["ls-tree", "HEAD", "--", relativePath]);
    if (tree.status !== 0 || !tree.stdout) return { path: relativePath, reason: "an outgoing file Geoffrey could not inspect safely" };
    if (/^120000\s/.test(tree.stdout)) return { path: relativePath, reason: "a symbolic link" };
    const shown = git(memoryRoot, ["show", `HEAD:${relativePath}`], { maxBuffer: 6 * 1024 * 1024 });
    if (shown.status !== 0 || Buffer.byteLength(shown.stdout, "utf8") > 5 * 1024 * 1024) {
      return { path: relativePath, reason: "an outgoing file beyond Geoffrey's credential-check limit" };
    }
    const reason = credentialReason(relativePath, shown.stdout);
    if (reason) return { path: relativePath, reason };
  }
  return null;
}

function currentStatus(memoryRoot, overrides = {}) {
  const branch = value(memoryRoot, ["branch", "--show-current"]);
  const dirty = Boolean(value(memoryRoot, ["status", "--porcelain"]));
  return {
    schema_version: 1,
    state: "not_checked",
    checked_at: new Date().toISOString(),
    phase,
    branch: branch || null,
    head: value(memoryRoot, ["rev-parse", "HEAD"]) || null,
    ahead: 0,
    behind: 0,
    dirty,
    message: "Geoffrey has not checked this memory repository yet.",
    recovery: null,
    ...overrides,
  };
}

function finish(memoryRoot, overrides, exitCode = 0) {
  const status = currentStatus(memoryRoot, overrides);
  atomicJson(statusPath, status);
  console.log(JSON.stringify(status));
  process.exitCode = exitCode;
}

function failWithoutRepo(message) {
  const status = {
    schema_version: 1,
    state: "not_configured",
    checked_at: new Date().toISOString(),
    phase,
    branch: null,
    head: null,
    ahead: 0,
    behind: 0,
    dirty: false,
    message,
    recovery: "Finish private-memory setup, then try again.",
  };
  atomicJson(statusPath, status);
  console.log(JSON.stringify(status));
  process.exitCode = 1;
}

const memoryRoot = existsSync(pointer) ? readFileSync(pointer, "utf8").split(/\r?\n/, 1)[0].trim() : "";
if (!memoryRoot || !existsSync(join(memoryRoot, "memory")) || !existsSync(join(memoryRoot, ".git"))) {
  failWithoutRepo("Private Geoffrey memory is not ready for GitHub sync.");
} else if (statusOnly) {
  let stored = null;
  try { stored = JSON.parse(readFileSync(statusPath, "utf8")); } catch { /* First status check. */ }
  const fallback = currentStatus(memoryRoot);
  if (git(memoryRoot, ["remote", "get-url", "origin"]).status !== 0) {
    stored = { state: "local_only", message: "Memory is saved on this Mac. GitHub backup is optional.",
      recovery: "Choose Set up GitHub backup in Memory when you are ready." };
  }
  const status = stored && typeof stored === "object" ? {
    ...fallback,
    ...stored,
    branch: fallback.branch,
    head: fallback.head,
    dirty: fallback.dirty,
  } : fallback;
  if (fallback.dirty && status.state === "synced") {
    status.state = "local_changes";
    status.message = "Private memory has changes on this Mac that are not backed up yet.";
    status.recovery = "Choose Sync now to inspect, version, and back up the changes.";
  }
  console.log(JSON.stringify(status));
} else {
  const branch = value(memoryRoot, ["branch", "--show-current"]);
  if (!branch) {
    finish(memoryRoot, {
      state: "needs_attention",
      message: "Private memory is not on a named Git branch.",
      recovery: "Open the memory folder and choose its normal branch before syncing.",
    }, 1);
  } else {
    const dirtyBefore = Boolean(value(memoryRoot, ["status", "--porcelain"]));
    if (dirtyBefore) {
      const credentialRisk = findCredentialRisk(memoryRoot);
      if (credentialRisk) {
        finish(memoryRoot, {
          state: "blocked_secret",
          message: `Geoffrey kept ${credentialRisk.path} on this Mac because it may contain ${credentialRisk.reason}. It was not backed up.`,
          recovery: "Remove the credential or move it to the approved secure store, then choose Sync now. Geoffrey did not delete the local file.",
        }, 1);
      } else {
        const added = git(memoryRoot, ["add", "--all"]);
        const committed = added.status === 0
          ? git(memoryRoot, ["-c", "commit.gpgsign=false", "commit", "-m", "Save Geoffrey app changes"])
          : added;
        if (added.status !== 0 || committed.status !== 0) {
          finish(memoryRoot, {
            state: "needs_attention",
            message: "Geoffrey saved the files on this Mac but could not record a local memory version.",
            recovery: "Open the memory folder to review the files, then try Sync now again.",
          }, 1);
        }
      }
    }

    if (process.exitCode !== 1) {
      const remote = git(memoryRoot, ["remote", "get-url", "origin"]);
      if (remote.status !== 0) {
        finish(memoryRoot, {
          state: "local_only",
          message: "Memory is saved on this Mac, but no GitHub backup is connected.",
          recovery: "Choose Set up GitHub backup in Memory. You can keep using Geoffrey without backup.",
        });
      } else {
        const fetched = git(memoryRoot, ["fetch", "--prune", "origin"], { timeout: 90_000 });
        if (fetched.status !== 0) {
          finish(memoryRoot, {
            state: "needs_attention",
            message: "Memory is saved on this Mac, but Geoffrey could not reach its GitHub backup.",
            recovery: "Check the internet connection and GitHub sign-in, then choose Sync now. Your local memory is unchanged.",
          }, 1);
        } else {
          const remoteRef = `refs/remotes/origin/${branch}`;
          const hasRemoteBranch = git(memoryRoot, ["show-ref", "--verify", "--quiet", remoteRef]).status === 0;
          if (!hasRemoteBranch) {
            const outgoingRisk = findOutgoingCredentialRisk(memoryRoot);
            if (outgoingRisk) {
              finish(memoryRoot, {
                state: "blocked_secret",
                message: `Geoffrey kept ${outgoingRisk.path} off GitHub because it may contain ${outgoingRisk.reason}.`,
                recovery: "Remove the credential from private-memory history or move it to the approved secure store, then choose Sync now. Geoffrey did not delete the local file.",
              }, 1);
            } else {
              const pushed = git(memoryRoot, ["push", "--set-upstream", "origin", `HEAD:refs/heads/${branch}`], { timeout: 90_000 });
              finish(memoryRoot, pushed.status === 0 ? {
                state: "synced",
                message: "Private memory is backed up to GitHub.",
                recovery: null,
              } : {
                state: "needs_attention",
                message: "Memory is saved on this Mac, but Geoffrey could not create its GitHub backup branch.",
                recovery: "Check GitHub access, then choose Sync now. Your local memory is unchanged.",
              }, pushed.status === 0 ? 0 : 1);
            }
          } else {
            const counts = value(memoryRoot, ["rev-list", "--left-right", "--count", `HEAD...${remoteRef}`]).split(/\s+/).map(Number);
            let ahead = Number.isFinite(counts[0]) ? counts[0] : 0;
            let behind = Number.isFinite(counts[1]) ? counts[1] : 0;
            let canPush = true;

            if (ahead > 0) {
              const outgoingRisk = findOutgoingCredentialRisk(memoryRoot, remoteRef);
              if (outgoingRisk) {
                finish(memoryRoot, {
                  state: "blocked_secret",
                  ahead,
                  behind,
                  message: `Geoffrey kept ${outgoingRisk.path} off GitHub because it may contain ${outgoingRisk.reason}.`,
                  recovery: "Remove the credential from private-memory history or move it to the approved secure store, then choose Sync now. Geoffrey did not delete the local file.",
                }, 1);
                canPush = false;
              }
            }

            if (process.exitCode !== 1 && behind > 0 && ahead === 0) {
              const advanced = git(memoryRoot, ["merge", "--ff-only", remoteRef]);
              canPush = advanced.status === 0;
              if (!canPush) {
                finish(memoryRoot, {
                  state: "needs_attention",
                  ahead,
                  behind,
                  message: "Memory is saved on this Mac, but Geoffrey could not apply the GitHub backup safely.",
                  recovery: "Your local memory is unchanged. Check the memory folder, then choose Sync now again.",
                }, 1);
              }
            } else if (process.exitCode !== 1 && behind > 0 && ahead > 0) {
              const originalHead = value(memoryRoot, ["rev-parse", "HEAD"]);
              const rebased = git(memoryRoot, ["rebase", remoteRef]);
              if (rebased.status !== 0) {
                git(memoryRoot, ["rebase", "--abort"]);
                const restored = value(memoryRoot, ["rev-parse", "HEAD"]) === originalHead;
                finish(memoryRoot, {
                  state: "conflict",
                  ahead,
                  behind,
                  message: "GitHub and this Mac changed the same memory. Geoffrey stopped without choosing one version.",
                  recovery: restored
                    ? "Your local memory is unchanged. Open the memory folder for review, then choose Sync now after resolving the conflicting file."
                    : "Open the memory folder before making more changes; Geoffrey could not confirm that the original local version was restored.",
                }, 1);
                canPush = false;
              } else {
                ahead = 1;
                behind = 0;
              }
            }

            if (process.exitCode !== 1 && canPush) {
              const remaining = value(memoryRoot, ["rev-list", "--left-right", "--count", `HEAD...${remoteRef}`]).split(/\s+/).map(Number);
              ahead = Number.isFinite(remaining[0]) ? remaining[0] : ahead;
              behind = Number.isFinite(remaining[1]) ? remaining[1] : behind;
              const pushed = ahead > 0
                ? git(memoryRoot, ["push", "origin", `HEAD:refs/heads/${branch}`], { timeout: 90_000 })
                : { status: 0 };
              finish(memoryRoot, pushed.status === 0 ? {
                state: "synced",
                ahead: 0,
                behind: 0,
                message: "Private memory is backed up to GitHub.",
                recovery: null,
              } : {
                state: "needs_attention",
                ahead,
                behind,
                message: "Memory is saved on this Mac, but GitHub did not accept the latest backup.",
                recovery: "Check GitHub access, then choose Sync now. Your local memory is unchanged.",
              }, pushed.status === 0 ? 0 : 1);
            }
          }
        }
      }
    }
  }
}
