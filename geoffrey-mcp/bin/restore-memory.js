#!/usr/bin/env node

// Restores private Geoffrey memory into a fresh local folder. The repository
// is cloned into a staging directory, validated, and only then made current.
// Credentials are never restored; the owner signs in again on the new Mac.

import { createHash } from "node:crypto";
import { spawnSync } from "node:child_process";
import { spawnGit } from "../src/git-process.js";
import {
  chmodSync,
  copyFileSync,
  existsSync,
  lstatSync,
  mkdirSync,
  readFileSync,
  readdirSync,
  renameSync,
  rmSync,
  writeFileSync,
} from "node:fs";
import { homedir } from "node:os";
import { basename, dirname, isAbsolute, join, relative, resolve, sep } from "node:path";

const args = process.argv.slice(2);
const sourceIndex = args.indexOf("--source");
const repositoryIndex = args.indexOf("--repository");
const targetIndex = args.indexOf("--target");
const source = sourceIndex >= 0 ? args[sourceIndex + 1]?.trim() : "";
const repositoryInput = repositoryIndex >= 0 ? args[repositoryIndex + 1]?.trim() : "";
const targetInput = targetIndex >= 0 ? args[targetIndex + 1]?.trim() : "";
const home = homedir();
const store = join(home, ".geoffrey");
const pointer = join(store, "current-memory");
const statusPath = join(store, "restore-v1.json");

function finish(payload, exitCode = 0) {
  console.log(JSON.stringify({ schema_version: 1, ...payload }));
  process.exitCode = exitCode;
}

function fail(message, recovery, exitCode = 1) {
  finish({ ok: false, state: "blocked", message, recovery }, exitCode);
}

function run(executable, parameters, options = {}) {
  const optionsForRun = {
    encoding: "utf8",
    env: { ...process.env, GH_PROMPT_DISABLED: "1", GIT_TERMINAL_PROMPT: "0" },
    timeout: options.timeout ?? 120_000,
    maxBuffer: options.maxBuffer ?? 6 * 1024 * 1024,
    stdio: ["ignore", "pipe", "pipe"],
  };
  return executable === "git" ? spawnGit(parameters, optionsForRun) : spawnSync(executable, parameters, optionsForRun);
}

function atomicJson(path, object) {
  mkdirSync(dirname(path), { recursive: true, mode: 0o700 });
  const temporary = `${path}.tmp-${process.pid}`;
  try {
    writeFileSync(temporary, JSON.stringify(object, null, 2) + "\n", { mode: 0o600 });
    chmodSync(temporary, 0o600);
    renameSync(temporary, path);
    chmodSync(path, 0o600);
  } finally {
    if (existsSync(temporary)) rmSync(temporary, { force: true });
  }
}

function atomicText(path, value) {
  mkdirSync(dirname(path), { recursive: true, mode: 0o700 });
  const temporary = `${path}.tmp-${process.pid}`;
  try {
    writeFileSync(temporary, value, { mode: 0o600 });
    chmodSync(temporary, 0o600);
    renameSync(temporary, path);
    chmodSync(path, 0o600);
  } finally {
    if (existsSync(temporary)) rmSync(temporary, { force: true });
  }
}

function normalizeGitHubRepository(value) {
  if (/^[A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+$/.test(value)) return value.replace(/\.git$/, "");
  try {
    const url = new URL(value);
    if (url.protocol !== "https:" || url.hostname.toLowerCase() !== "github.com" || url.username || url.password || url.search || url.hash) return null;
    const path = url.pathname.replace(/^\/+|\/+$/g, "").replace(/\.git$/, "");
    return /^[A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+$/.test(path) ? path : null;
  } catch {
    return null;
  }
}

function credentialReason(path, content) {
  const name = basename(path).toLowerCase();
  if (name === ".env" || name === "accounts.json" || name === "credentials.json"
      || /\.(?:pem|key|p12|pfx|token|secret)$/.test(name)) return "a credential-bearing filename";
  if (/-----BEGIN [^-]*PRIVATE KEY-----/i.test(content)) return "a private key";
  if (/\b(?:sk-ant-|gh[pousr]_|ya29\.)[A-Za-z0-9._-]+\b/i.test(content)) return "an access token";
  if (/\bBearer\s+[A-Za-z0-9._~+/-]{12,}/i.test(content)) return "a bearer credential";
  if (/\b(?:access_token|refresh_token|client_secret|api_key|password)\s*[:=]\s*["']?[^\s"']+/i.test(content)) return "a named credential";
  return null;
}

function hash(path) {
  return createHash("sha256").update(readFileSync(path)).digest("hex");
}

function inside(root, candidate) {
  const base = resolve(root) + sep;
  return resolve(candidate).startsWith(base);
}

function validateTrackedFiles(root) {
  const checkout = run("git", ["-C", root, "status", "--porcelain=v1", "--untracked-files=all"]);
  if (checkout.status !== 0 || checkout.stdout.trim()) {
    throw new Error("The restored checkout contains files or changes that were not present in the verified commit.");
  }
  const listed = run("git", ["-C", root, "ls-tree", "-r", "-z", "HEAD"]);
  if (listed.status !== 0) throw new Error("Geoffrey could not inspect the restored repository safely.");
  for (const entry of listed.stdout.split("\0").filter(Boolean)) {
    const match = entry.match(/^(\d+)\s+(\S+)\s+[a-f0-9]+\t([\s\S]+)$/);
    if (!match) throw new Error("Geoffrey could not inspect one of the restored files safely.");
    const [, mode, type, path] = match;
    if (type !== "blob" || !["100644", "100755"].includes(mode)) {
      throw new Error(`The backup contains an unsafe link or nested repository at ${path}.`);
    }
    const shown = run("git", ["-C", root, "show", `HEAD:${path}`]);
    if (shown.status !== 0 || Buffer.byteLength(shown.stdout, "utf8") > 5 * 1024 * 1024) {
      throw new Error(`Geoffrey could not safely inspect ${path}.`);
    }
    const reason = credentialReason(path, shown.stdout);
    if (reason) throw new Error(`The backup contains ${reason} at ${path}.`);
    const checkedOutPath = resolve(root, path);
    if (!inside(root, checkedOutPath) || !existsSync(checkedOutPath) || !lstatSync(checkedOutPath).isFile() || lstatSync(checkedOutPath).isSymbolicLink()) {
      throw new Error(`The restored file ${path} is missing or unsafe.`);
    }
    if (lstatSync(checkedOutPath).size > 5 * 1024 * 1024) throw new Error(`Geoffrey could not safely inspect ${path}.`);
    const checkoutReason = credentialReason(path, readFileSync(checkedOutPath, "utf8"));
    if (checkoutReason) throw new Error(`The restored checkout contains ${checkoutReason} at ${path}.`);
  }
}

function protectPrivateTree(path) {
  const metadata = lstatSync(path);
  if (metadata.isSymbolicLink()) throw new Error(`The restored checkout contains an unsafe link at ${path}.`);
  if (metadata.isDirectory()) {
    chmodSync(path, 0o700);
    for (const entry of readdirSync(path)) protectPrivateTree(join(path, entry));
  } else if (metadata.isFile()) {
    chmodSync(path, metadata.mode & 0o100 ? 0o700 : 0o600);
  }
}

function currentMemoryPath() {
  if (!existsSync(pointer)) return "";
  try { return readFileSync(pointer, "utf8").split(/\r?\n/, 1)[0].trim(); } catch { return ""; }
}

function validateManifest(root) {
  const path = join(root, "memory", "portable-state.json");
  if (!existsSync(path) || !lstatSync(path).isFile() || lstatSync(path).isSymbolicLink()) {
    throw new Error("This repository does not contain Geoffrey recovery information.");
  }
  let manifest;
  try { manifest = JSON.parse(readFileSync(path, "utf8")); } catch { throw new Error("The Geoffrey recovery information is not valid JSON."); }
  if (manifest.schema_version !== 1 || manifest.restore?.format_version !== 1 || manifest.restore?.secrets_included !== false) {
    throw new Error("This recovery map is unsupported or does not prove that secrets were excluded.");
  }
  if (!Array.isArray(manifest.skills) || !Array.isArray(manifest.connectors)) {
    throw new Error("This recovery map is missing skills or connection definitions.");
  }
  for (const skill of manifest.skills) {
    if (skill?.approved !== true || typeof skill.path !== "string" || !/^[a-f0-9]{64}$/.test(skill.sha256 ?? "")) {
      throw new Error("The recovery map contains an invalid approved-skill record.");
    }
    const skillPath = resolve(root, skill.path);
    if (!inside(root, skillPath) || !existsSync(skillPath) || !lstatSync(skillPath).isFile() || lstatSync(skillPath).isSymbolicLink()) {
      throw new Error(`The approved skill ${skill.name ?? skill.id ?? "unknown"} is missing or unsafe.`);
    }
    if (hash(skillPath) !== skill.sha256) throw new Error(`The approved skill ${skill.name ?? skill.id ?? "unknown"} changed after the recovery map was created.`);
  }
  for (const connector of manifest.connectors) {
    if (!connector || connector.secret_included !== false || typeof connector.id !== "string" || typeof connector.restore_action !== "string") {
      throw new Error("The recovery map contains an unsafe connection definition.");
    }
  }
  return manifest;
}

if (Boolean(source) === Boolean(repositoryInput)) {
  fail("Choose exactly one private-memory source.", "Enter a GitHub owner/repository name, or provide one local source for testing.", 2);
} else if (!targetInput || !isAbsolute(targetInput)) {
  fail("Choose an absolute folder for restored Geoffrey memory.", "Use a new, empty location such as your home Geoffrey folder.", 2);
} else {
  const target = resolve(targetInput);
  const current = currentMemoryPath();
  if (current && existsSync(join(current, "memory"))) {
    fail("Private Geoffrey memory is already configured on this Mac.", "Keep the current memory, or move it aside deliberately before starting a restore.");
  } else if (existsSync(target)) {
    fail("The restore folder already exists.", "Choose a new folder so Geoffrey cannot overwrite existing files.");
  } else {
    const repository = repositoryInput ? normalizeGitHubRepository(repositoryInput) : null;
    if (repositoryInput && !repository) {
      fail("Enter a GitHub repository as owner/repository or a plain https://github.com URL.", "Remove credentials, query strings, fragments, and unrelated hosts from the repository address.", 2);
    } else if (source && (!isAbsolute(source) || !existsSync(join(resolve(source), ".git")))) {
      fail("The local recovery source is not a Git repository.", "Choose an absolute path to a private Geoffrey memory repository.", 2);
    } else {
      const parent = dirname(target);
      const staging = join(parent, `.${basename(target)}.geoffrey-restoring-${process.pid}`);
      const safeGitTemplate = `${staging}-git-template`;
      let installedTarget = false;
      let selectedTarget = false;
      try {
        mkdirSync(parent, { recursive: true, mode: 0o700 });
        mkdirSync(safeGitTemplate, { recursive: true, mode: 0o700 });
        const cloned = repository
          ? run("gh", ["repo", "clone", repository, staging, "--", `--template=${safeGitTemplate}`], { timeout: 180_000 })
          : run("git", ["clone", "--no-local", `--template=${safeGitTemplate}`, resolve(source), staging], { timeout: 180_000 });
        if (cloned.status !== 0) {
          const detail = (cloned.stderr || cloned.stdout || "").trim().split(/\r?\n/).slice(-1)[0];
          throw new Error(detail ? `Geoffrey could not clone the private backup: ${detail}` : "Geoffrey could not clone the private backup.");
        }
        validateTrackedFiles(staging);
        const manifest = validateManifest(staging);
        protectPrivateTree(staging);
        renameSync(staging, target);
        installedTarget = true;

        let pointerBackup = null;
        if (existsSync(pointer)) {
          const stamp = new Date().toISOString().replace(/[:.]/g, "-");
          const backupDirectory = join(store, "backups", `pre-restore-${stamp}`);
          mkdirSync(backupDirectory, { recursive: true, mode: 0o700 });
          pointerBackup = join(backupDirectory, "current-memory");
          copyFileSync(pointer, pointerBackup);
          chmodSync(pointerBackup, 0o600);
        }
        atomicText(pointer, target + "\n");
        selectedTarget = true;
        const accounts = manifest.connectors.filter((item) => item.kind === "email_calendar");
        const claudeConnections = manifest.connectors.filter((item) => item.kind === "mcp" || item.kind === "plugin");
        const result = {
          ok: true,
          state: "restored",
          restored_at: new Date().toISOString(),
          memory_path: target,
          source: repository ? `github:${repository}` : "local_git_repository",
          branch: run("git", ["-C", target, "branch", "--show-current"]).stdout.trim() || null,
          skills_count: manifest.skills.length,
          connectors_count: manifest.connectors.length,
          reconnect_count: manifest.connectors.filter((item) => item.restore_action).length,
          email_accounts: accounts.map(({ id, name, provider, account, restore_action }) => ({ id, name, provider, account, restore_action })),
          claude_connections: claudeConnections.map(({ id, name, kind, restore_action }) => ({ id, name, kind, restore_action })),
          credentials_restored: false,
          pointer_backup: pointerBackup,
          message: "Private Geoffrey memory was restored and verified.",
          recovery: manifest.connectors.length
            ? "Reconnect the listed accounts and Claude connections. Credentials were intentionally not restored."
            : "No connection definitions require sign-in.",
        };
        atomicJson(statusPath, { schema_version: 1, ...result });
        finish(result);
      } catch (error) {
        if (existsSync(staging)) rmSync(staging, { recursive: true, force: true });
        if (installedTarget && !selectedTarget && existsSync(target)) rmSync(target, { recursive: true, force: true });
        if (selectedTarget) {
          finish({
            ok: true,
            state: "restored",
            memory_path: target,
            credentials_restored: false,
            message: "Private Geoffrey memory was restored and verified.",
            recovery: "The memory is selected, but Geoffrey could not save its restore receipt. Reopen Memory to refresh status.",
          });
        } else {
          fail(error.message || "Geoffrey could not restore this private backup.", "No current memory was replaced. Review the backup and try again.");
        }
      } finally {
        if (existsSync(safeGitTemplate)) rmSync(safeGitTemplate, { recursive: true, force: true });
      }
    }
  }
}
