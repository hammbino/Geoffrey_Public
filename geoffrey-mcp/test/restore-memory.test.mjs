import assert from "node:assert/strict";
import { execFileSync, spawnSync } from "node:child_process";
import { chmodSync, mkdtempSync, mkdirSync, readFileSync, rmSync, statSync, symlinkSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import test from "node:test";

const here = dirname(fileURLToPath(import.meta.url));
const portableScript = join(here, "../bin/portable-state.js");
const restoreScript = join(here, "../bin/restore-memory.js");

function git(root, ...parameters) {
  return execFileSync("git", ["-C", root, "-c", "commit.gpgsign=false", ...parameters], { encoding: "utf8" });
}

function makeBackup(root) {
  const sourceHome = join(root, "first-mac");
  const memory = join(sourceHome, "private-memory");
  mkdirSync(join(sourceHome, ".geoffrey"), { recursive: true });
  mkdirSync(join(memory, "memory", "skills"), { recursive: true });
  writeFileSync(join(sourceHome, ".geoffrey", "current-memory"), memory + "\n");
  writeFileSync(join(sourceHome, ".geoffrey", "accounts.json"), JSON.stringify({ accounts: [{
    id: "work", provider: "google", email: "owner@example.com", purpose: "Work", refresh_token: "never-copy-this",
  }] }));
  writeFileSync(join(memory, "memory", "skills", "briefing.md"), "# Briefing\n");
  git(memory, "init", "-b", "main");
  git(memory, "config", "user.name", "Geoffrey Test");
  git(memory, "config", "user.email", "geoffrey@example.com");
  git(memory, "add", ".");
  git(memory, "commit", "-m", "Initial private memory");
  execFileSync("node", [portableScript, "--write", "--capabilities", join(root, "capabilities.json")], {
    env: { ...process.env, HOME: sourceHome }, encoding: "utf8",
  });
  git(memory, "add", "memory/portable-state.json");
  git(memory, "commit", "-m", "Add recovery map");
  return { sourceHome, memory };
}

test("restores verified private memory into a clean second environment without credentials", () => {
  const root = mkdtempSync(join(tmpdir(), "geoffrey-restore-"));
  try {
    writeFileSync(join(root, "capabilities.json"), JSON.stringify([
      { id: "mcp:social", name: "social", type: "mcp", enabled: true },
    ]));
    const { memory } = makeBackup(root);
    const secondHome = join(root, "second-mac");
    const target = join(secondHome, "Geoffrey");
    mkdirSync(secondHome, { recursive: true });
    const restored = JSON.parse(execFileSync("node", [restoreScript, "--source", memory, "--target", target], {
      env: { ...process.env, HOME: secondHome }, encoding: "utf8",
    }));

    assert.equal(restored.ok, true);
    assert.equal(restored.state, "restored");
    assert.equal(restored.skills_count, 1);
    assert.equal(restored.connectors_count, 2);
    assert.equal(restored.reconnect_count, 2);
    assert.equal(restored.credentials_restored, false);
    assert.equal(readFileSync(join(secondHome, ".geoffrey", "current-memory"), "utf8").trim(), target);
    assert.equal(readFileSync(join(target, "memory", "skills", "briefing.md"), "utf8"), "# Briefing\n");
    assert.equal(statSync(join(secondHome, ".geoffrey", "current-memory")).mode & 0o777, 0o600);
    assert.equal(statSync(join(secondHome, ".geoffrey", "restore-v1.json")).mode & 0o777, 0o600);
    assert.equal(statSync(target).mode & 0o777, 0o700);
    assert.equal(statSync(join(target, "memory", "skills", "briefing.md")).mode & 0o777, 0o600);
    assert.throws(() => readFileSync(join(secondHome, ".geoffrey", "accounts.json")));
    assert.doesNotMatch(readFileSync(join(secondHome, ".geoffrey", "restore-v1.json"), "utf8"), /never-copy-this|refresh_token/);
  } finally {
    rmSync(root, { recursive: true, force: true });
  }
});

test("refuses a tampered recovery source without changing second-environment state", () => {
  const root = mkdtempSync(join(tmpdir(), "geoffrey-restore-tamper-"));
  try {
    writeFileSync(join(root, "capabilities.json"), "[]\n");
    const { memory } = makeBackup(root);
    writeFileSync(join(memory, "memory", "skills", "briefing.md"), "# Tampered\n");
    git(memory, "add", "memory/skills/briefing.md");
    git(memory, "commit", "-m", "Tamper after recovery map");
    const secondHome = join(root, "second-mac");
    const target = join(secondHome, "Geoffrey");
    mkdirSync(secondHome, { recursive: true });
    const attempt = spawnSync("node", [restoreScript, "--source", memory, "--target", target], {
      env: { ...process.env, HOME: secondHome }, encoding: "utf8",
    });
    const result = JSON.parse(attempt.stdout);
    assert.notEqual(attempt.status, 0);
    assert.equal(result.ok, false);
    assert.match(result.message, /changed after the recovery map/);
    assert.throws(() => readFileSync(join(secondHome, ".geoffrey", "current-memory")));
  } finally {
    rmSync(root, { recursive: true, force: true });
  }
});

test("refuses credential-bearing files without selecting the restored clone", () => {
  const root = mkdtempSync(join(tmpdir(), "geoffrey-restore-credential-"));
  try {
    writeFileSync(join(root, "capabilities.json"), "[]\n");
    const { memory } = makeBackup(root);
    writeFileSync(join(memory, "credentials.json"), '{"access_token":"must-not-restore"}\n');
    git(memory, "add", "credentials.json");
    git(memory, "commit", "-m", "Unsafe credential file");
    const secondHome = join(root, "second-mac");
    const target = join(secondHome, "Geoffrey");
    mkdirSync(secondHome, { recursive: true });
    const attempt = spawnSync("node", [restoreScript, "--source", memory, "--target", target], {
      env: { ...process.env, HOME: secondHome }, encoding: "utf8",
    });
    const result = JSON.parse(attempt.stdout);
    assert.notEqual(attempt.status, 0);
    assert.equal(result.ok, false);
    assert.match(result.message, /credential-bearing filename/);
    assert.throws(() => readFileSync(join(secondHome, ".geoffrey", "current-memory")));
  } finally {
    rmSync(root, { recursive: true, force: true });
  }
});

test("refuses a token-shaped bearer credential but allows explanatory security language", () => {
  const root = mkdtempSync(join(tmpdir(), "geoffrey-restore-bearer-"));
  try {
    writeFileSync(join(root, "capabilities.json"), "[]\n");
    const { memory } = makeBackup(root);
    writeFileSync(join(memory, "memory", "security.md"), "Bearer headers never belong in private memory.\nBearer abcdefghijklmnopqrstuvwxyz012345\n");
    git(memory, "add", "memory/security.md");
    git(memory, "commit", "-m", "Unsafe bearer credential");
    const secondHome = join(root, "second-mac");
    const target = join(secondHome, "Geoffrey");
    mkdirSync(secondHome, { recursive: true });
    const attempt = spawnSync("node", [restoreScript, "--source", memory, "--target", target], {
      env: { ...process.env, HOME: secondHome }, encoding: "utf8",
    });
    const result = JSON.parse(attempt.stdout);
    assert.notEqual(attempt.status, 0);
    assert.equal(result.ok, false);
    assert.match(result.message, /bearer credential/);
    assert.throws(() => readFileSync(join(secondHome, ".geoffrey", "current-memory")));
  } finally {
    rmSync(root, { recursive: true, force: true });
  }
});

test("refuses symbolic links from the backup", () => {
  const root = mkdtempSync(join(tmpdir(), "geoffrey-restore-link-"));
  try {
    writeFileSync(join(root, "capabilities.json"), "[]\n");
    const { memory } = makeBackup(root);
    symlinkSync("/private/tmp/outside-geoffrey", join(memory, "memory", "outside-link"));
    git(memory, "add", "memory/outside-link");
    git(memory, "commit", "-m", "Unsafe symbolic link");
    const secondHome = join(root, "second-mac");
    const target = join(secondHome, "Geoffrey");
    mkdirSync(secondHome, { recursive: true });
    const attempt = spawnSync("node", [restoreScript, "--source", memory, "--target", target], {
      env: { ...process.env, HOME: secondHome }, encoding: "utf8",
    });
    const result = JSON.parse(attempt.stdout);
    assert.notEqual(attempt.status, 0);
    assert.equal(result.ok, false);
    assert.match(result.message, /unsafe link/);
    assert.throws(() => readFileSync(join(secondHome, ".geoffrey", "current-memory")));
  } finally {
    rmSync(root, { recursive: true, force: true });
  }
});

test("refuses to overwrite an existing restore folder", () => {
  const root = mkdtempSync(join(tmpdir(), "geoffrey-restore-overwrite-"));
  try {
    writeFileSync(join(root, "capabilities.json"), "[]\n");
    const { memory } = makeBackup(root);
    const secondHome = join(root, "second-mac");
    const target = join(secondHome, "Geoffrey");
    mkdirSync(target, { recursive: true });
    writeFileSync(join(target, "keep-me.txt"), "preserved\n");
    const attempt = spawnSync("node", [restoreScript, "--source", memory, "--target", target], {
      env: { ...process.env, HOME: secondHome }, encoding: "utf8",
    });
    const result = JSON.parse(attempt.stdout);
    assert.notEqual(attempt.status, 0);
    assert.equal(result.ok, false);
    assert.match(result.message, /already exists/);
    assert.equal(readFileSync(join(target, "keep-me.txt"), "utf8"), "preserved\n");
    assert.throws(() => readFileSync(join(secondHome, ".geoffrey", "current-memory")));
  } finally {
    rmSync(root, { recursive: true, force: true });
  }
});

test("uses a clean Git template so checkout hooks cannot add unverified files", () => {
  const root = mkdtempSync(join(tmpdir(), "geoffrey-restore-hook-"));
  try {
    writeFileSync(join(root, "capabilities.json"), "[]\n");
    const { memory } = makeBackup(root);
    const template = join(root, "unsafe-template");
    const hook = join(template, "hooks", "post-checkout");
    mkdirSync(dirname(hook), { recursive: true });
    writeFileSync(hook, "#!/bin/sh\nprintf 'unverified\\n' > checkout-created.txt\n");
    chmodSync(hook, 0o700);
    const secondHome = join(root, "second-mac");
    const target = join(secondHome, "Geoffrey");
    mkdirSync(secondHome, { recursive: true });
    const restored = JSON.parse(execFileSync("node", [restoreScript, "--source", memory, "--target", target], {
      env: { ...process.env, HOME: secondHome, GIT_TEMPLATE_DIR: template }, encoding: "utf8",
    }));
    assert.equal(restored.ok, true);
    assert.throws(() => readFileSync(join(target, "checkout-created.txt")));
  } finally {
    rmSync(root, { recursive: true, force: true });
  }
});

test("removes the installed clone if selecting it as current memory fails", () => {
  const root = mkdtempSync(join(tmpdir(), "geoffrey-restore-pointer-"));
  try {
    writeFileSync(join(root, "capabilities.json"), "[]\n");
    const { memory } = makeBackup(root);
    const secondHome = join(root, "second-mac");
    const target = join(secondHome, "Geoffrey");
    mkdirSync(join(secondHome, ".geoffrey", "current-memory"), { recursive: true });
    const attempt = spawnSync("node", [restoreScript, "--source", memory, "--target", target], {
      env: { ...process.env, HOME: secondHome }, encoding: "utf8",
    });
    const result = JSON.parse(attempt.stdout);
    assert.notEqual(attempt.status, 0);
    assert.equal(result.ok, false);
    assert.equal(result.recovery, "No current memory was replaced. Review the backup and try again.");
    assert.throws(() => statSync(target));
    assert.equal(statSync(join(secondHome, ".geoffrey", "current-memory")).isDirectory(), true);
  } finally {
    rmSync(root, { recursive: true, force: true });
  }
});
