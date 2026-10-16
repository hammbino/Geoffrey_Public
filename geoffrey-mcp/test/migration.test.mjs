import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import { mkdtempSync, mkdirSync, readFileSync, rmSync, statSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import test from "node:test";

const here = dirname(fileURLToPath(import.meta.url));
const script = join(here, "../bin/migrate-legacy.js");

test("legacy migration preserves private state without leaking tokens", () => {
  const fixtureHome = mkdtempSync(join(tmpdir(), "geoffrey-migration-test-"));
  const store = join(fixtureHome, ".geoffrey");
  const memory = join(fixtureHome, "geoffrey-memory");
  const legacy = join(fixtureHome, "Geoffrey", "bin");
  const accounts = {
    accounts: [{
      id: "work",
      provider: "google",
      email: "owner@example.com",
      purpose: "work",
      refresh_token: "must-never-appear-in-the-manifest",
    }],
  };

  try {
    mkdirSync(store, { recursive: true });
    mkdirSync(join(memory, "memory", "skills"), { recursive: true });
    mkdirSync(join(memory, ".git"), { recursive: true });
    mkdirSync(legacy, { recursive: true });
    writeFileSync(join(legacy, "geoffrey"), "#!/bin/sh\n");
    writeFileSync(join(memory, "memory", "social-briefing.md"), "fixture\n");
    writeFileSync(join(store, "accounts.json"), JSON.stringify(accounts));
    writeFileSync(join(store, "current-memory"), memory + "\n");

    const output = execFileSync("node", [script, "--write", "--engine-root", join(fixtureHome, "Library", "Application Support", "Geoffrey", "engine")], {
      env: { ...process.env, HOME: fixtureHome },
      encoding: "utf8",
    });
    const result = JSON.parse(output);
    const manifestText = readFileSync(join(store, "migration-v1.json"), "utf8");

    assert.equal(result.state, "migrated");
    assert.equal(result.legacy_install.exists, true);
    assert.equal(result.engine.self_contained, true);
    assert.equal(result.private_state.accounts.count, 1);
    assert.deepEqual(result.private_state.memory_repository.automation_candidates, ["memory/social-briefing.md"]);
    assert.doesNotMatch(manifestText, /must-never-appear/);
    assert.deepEqual(
      JSON.parse(readFileSync(join(store, "backups", "pre-desktop-v1", "accounts.json"), "utf8")),
      accounts
    );
    assert.equal(statSync(join(store, "migration-v1.json")).mode & 0o777, 0o600);
    assert.equal(statSync(join(store, "backups", "pre-desktop-v1", "accounts.json")).mode & 0o777, 0o600);
  } finally {
    rmSync(fixtureHome, { recursive: true, force: true });
  }
});
