import assert from "node:assert/strict";
import { execFileSync, spawnSync } from "node:child_process";
import { existsSync, mkdtempSync, mkdirSync, readFileSync, rmSync, statSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import test from "node:test";

const here = dirname(fileURLToPath(import.meta.url));
const script = join(here, "../bin/memory-sync.js");

function git(cwd, ...args) {
  return execFileSync("git", ["-C", cwd, ...args], { encoding: "utf8", stdio: ["ignore", "pipe", "pipe"] });
}

function setup({ remote = true } = {}) {
  const root = mkdtempSync(join(tmpdir(), "geoffrey-memory-sync-"));
  const memory = join(root, "memory-repo");
  const bare = join(root, "remote.git");
  mkdirSync(join(root, ".geoffrey"), { recursive: true });
  mkdirSync(join(memory, "memory"), { recursive: true });
  execFileSync("git", ["init", "-b", "main", memory]);
  git(memory, "config", "user.email", "geoffrey@example.test");
  git(memory, "config", "user.name", "Geoffrey Test");
  writeFileSync(join(memory, "memory", "user.md"), "# Owner\n\nBase\n");
  git(memory, "add", ".");
  git(memory, "commit", "-m", "Initial memory");
  if (remote) {
    execFileSync("git", ["init", "--bare", bare]);
    git(memory, "remote", "add", "origin", bare);
    git(memory, "push", "-u", "origin", "main");
  }
  writeFileSync(join(root, ".geoffrey", "current-memory"), memory + "\n");
  return { root, memory, bare };
}

function cloneRemote(item, name = "other") {
  const path = join(item.root, name);
  execFileSync("git", ["clone", "-b", "main", item.bare, path], { stdio: "ignore" });
  git(path, "config", "user.email", `${name}@example.test`);
  git(path, "config", "user.name", "Other Geoffrey");
  return path;
}

function run(item, ...extra) {
  return spawnSync("node", [script, ...extra], { env: { ...process.env, HOME: item.root }, encoding: "utf8" });
}

test("commits and pushes local memory changes with machine-readable proof", () => {
  const item = setup();
  try {
    writeFileSync(join(item.memory, "memory", "user.md"), "# Owner\n\nUpdated locally\n");
    const result = run(item, "--phase", "test success");
    assert.equal(result.status, 0, result.stderr || result.stdout);
    const status = JSON.parse(result.stdout);
    assert.equal(status.state, "synced");
    assert.equal(status.dirty, false);
    assert.equal(git(item.memory, "rev-parse", "HEAD").trim(), git(item.memory, "rev-parse", "origin/main").trim());
    const stored = join(item.root, ".geoffrey", "memory-sync.json");
    assert.equal(JSON.parse(readFileSync(stored, "utf8")).state, "synced");
    assert.equal(statSync(stored).mode & 0o777, 0o600);
  } finally {
    rmSync(item.root, { recursive: true, force: true });
  }
});

test("fast-forwards remote-only memory changes", () => {
  const item = setup();
  try {
    const other = cloneRemote(item);
    writeFileSync(join(other, "memory", "user.md"), "# Owner\n\nUpdated remotely\n");
    git(other, "add", ".");
    git(other, "commit", "-m", "Remote update");
    git(other, "push", "origin", "main");
    const result = run(item);
    assert.equal(result.status, 0, result.stderr || result.stdout);
    assert.equal(JSON.parse(result.stdout).state, "synced");
    assert.match(readFileSync(join(item.memory, "memory", "user.md"), "utf8"), /Updated remotely/);
  } finally {
    rmSync(item.root, { recursive: true, force: true });
  }
});

test("rebases independent local and remote changes, then pushes both", () => {
  const item = setup();
  try {
    const other = cloneRemote(item);
    writeFileSync(join(other, "memory", "remote.md"), "Remote fact\n");
    git(other, "add", ".");
    git(other, "commit", "-m", "Remote fact");
    git(other, "push", "origin", "main");
    writeFileSync(join(item.memory, "memory", "local.md"), "Local fact\n");
    const result = run(item);
    assert.equal(result.status, 0, result.stderr || result.stdout);
    assert.equal(JSON.parse(result.stdout).state, "synced");
    assert.equal(existsSync(join(item.memory, "memory", "remote.md")), true);
    assert.equal(existsSync(join(item.memory, "memory", "local.md")), true);
    assert.equal(git(item.memory, "rev-parse", "HEAD").trim(), git(item.memory, "rev-parse", "origin/main").trim());
  } finally {
    rmSync(item.root, { recursive: true, force: true });
  }
});

test("aborts a real conflict and preserves the original local branch and file", () => {
  const item = setup();
  try {
    const other = cloneRemote(item);
    writeFileSync(join(other, "memory", "user.md"), "# Owner\n\nRemote version\n");
    git(other, "add", ".");
    git(other, "commit", "-m", "Remote version");
    git(other, "push", "origin", "main");
    writeFileSync(join(item.memory, "memory", "user.md"), "# Owner\n\nLocal version\n");
    const result = run(item);
    assert.notEqual(result.status, 0);
    const status = JSON.parse(result.stdout);
    assert.equal(status.state, "conflict");
    assert.match(status.recovery, /local memory is unchanged/i);
    assert.match(readFileSync(join(item.memory, "memory", "user.md"), "utf8"), /Local version/);
    assert.equal(existsSync(join(item.memory, ".git", "rebase-merge")), false);
    assert.equal(existsSync(join(item.memory, ".git", "rebase-apply")), false);
  } finally {
    rmSync(item.root, { recursive: true, force: true });
  }
});

test("reports local-only state when no GitHub remote is configured", () => {
  const item = setup({ remote: false });
  try {
    const result = run(item);
    assert.equal(result.status, 0, result.stderr || result.stdout);
    const status = JSON.parse(result.stdout);
    assert.equal(status.state, "local_only");
    assert.match(status.message, /saved on this Mac/i);
  } finally {
    rmSync(item.root, { recursive: true, force: true });
  }
});

test("refuses credential-like files without committing, pushing, or deleting them", () => {
  const item = setup();
  try {
    const localBefore = git(item.memory, "rev-parse", "HEAD").trim();
    const remoteBefore = git(item.memory, "rev-parse", "origin/main").trim();
    const credentialPath = join(item.memory, "memory", "token.txt");
    writeFileSync(credentialPath, "api_key=sk-ant-DO-NOT-PUSH-123\n");
    const result = run(item);
    assert.notEqual(result.status, 0);
    const status = JSON.parse(result.stdout);
    assert.equal(status.state, "blocked_secret");
    assert.match(status.message, /token\.txt/);
    assert.equal(git(item.memory, "rev-parse", "HEAD").trim(), localBefore);
    assert.equal(git(item.memory, "rev-parse", "origin/main").trim(), remoteBefore);
    assert.equal(readFileSync(credentialPath, "utf8"), "api_key=sk-ant-DO-NOT-PUSH-123\n");
  } finally {
    rmSync(item.root, { recursive: true, force: true });
  }
});

test("refuses a credential already committed locally before it reaches GitHub", () => {
  const item = setup();
  try {
    const remoteBefore = git(item.memory, "rev-parse", "origin/main").trim();
    const credentialPath = join(item.memory, "memory", "precommitted.token");
    writeFileSync(credentialPath, "sk-ant-PRECOMMITTED-SECRET-123\n");
    git(item.memory, "add", ".");
    git(item.memory, "commit", "-m", "Legacy save committed a credential");
    const localSecretCommit = git(item.memory, "rev-parse", "HEAD").trim();

    const result = run(item);
    assert.notEqual(result.status, 0);
    const status = JSON.parse(result.stdout);
    assert.equal(status.state, "blocked_secret");
    assert.match(status.message, /precommitted\.token/);
    assert.equal(git(item.memory, "rev-parse", "HEAD").trim(), localSecretCommit);
    assert.equal(git(item.memory, "rev-parse", "origin/main").trim(), remoteBefore);
    assert.equal(readFileSync(credentialPath, "utf8"), "sk-ant-PRECOMMITTED-SECRET-123\n");
  } finally {
    rmSync(item.root, { recursive: true, force: true });
  }
});

test("read-only status reports waiting local changes without committing or pushing", () => {
  const item = setup();
  try {
    assert.equal(run(item).status, 0);
    const before = git(item.memory, "rev-parse", "HEAD").trim();
    writeFileSync(join(item.memory, "memory", "user.md"), "# Owner\n\nWaiting change\n");
    const result = run(item, "--status");
    assert.equal(result.status, 0, result.stderr || result.stdout);
    const status = JSON.parse(result.stdout);
    assert.equal(status.state, "local_changes");
    assert.equal(status.dirty, true);
    assert.equal(git(item.memory, "rev-parse", "HEAD").trim(), before);
    assert.equal(git(item.memory, "rev-parse", "origin/main").trim(), before);
  } finally {
    rmSync(item.root, { recursive: true, force: true });
  }
});
