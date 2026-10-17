import assert from "node:assert/strict";
import { execFileSync, spawnSync } from "node:child_process";
import { chmodSync, existsSync, mkdtempSync, mkdirSync, readFileSync, rmSync, statSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";
import test from "node:test";

const here = dirname(fileURLToPath(import.meta.url));
const storeModule = pathToFileURL(join(here, "../src/store.js")).href;
const accountStatusScript = join(here, "../bin/account-status.js");

function fixture(prefix) {
  const root = mkdtempSync(join(tmpdir(), prefix));
  const fakeSecurity = join(root, "fake-security.mjs");
  const keychain = join(root, "fake-keychain.json");
  const log = join(root, "fake-keychain-args.json");
  writeFileSync(fakeSecurity, `#!/usr/bin/env node
import { existsSync, readFileSync, writeFileSync } from "node:fs";
const args = process.argv.slice(2);
const statePath = process.env.GEOFFREY_FAKE_KEYCHAIN;
const logPath = process.env.GEOFFREY_FAKE_KEYCHAIN_LOG;
const state = existsSync(statePath) ? JSON.parse(readFileSync(statePath, "utf8")) : {};
const calls = existsSync(logPath) ? JSON.parse(readFileSync(logPath, "utf8")) : [];
calls.push(args);
writeFileSync(logPath, JSON.stringify(calls));
const value = (flag) => args[args.indexOf(flag) + 1];
const key = value("-s") + "\\u0000" + value("-a");
if (args[0] === "add-generic-password") {
  if (process.env.GEOFFREY_FAKE_KEYCHAIN_FAIL_ADD === "1"
      || process.env.GEOFFREY_FAKE_KEYCHAIN_FAIL_ACCOUNT === value("-a")) process.exit(1);
  const input = readFileSync(0, "utf8").trimEnd().split(/\\r?\\n/);
  if (input.length < 2 || input[0] !== input[1]) process.exit(3);
  state[key] = input[0];
  writeFileSync(statePath, JSON.stringify(state));
  process.exit(0);
}
if (args[0] === "find-generic-password") {
  if (!Object.hasOwn(state, key)) process.exit(44);
  process.stdout.write(state[key]);
  process.exit(0);
}
if (args[0] === "delete-generic-password") {
  if (!Object.hasOwn(state, key)) process.exit(44);
  delete state[key];
  writeFileSync(statePath, JSON.stringify(state));
  process.exit(0);
}
process.exit(2);
`);
  chmodSync(fakeSecurity, 0o700);
  return {
    root,
    store: join(root, ".geoffrey"),
    fakeSecurity,
    keychain,
    log,
    env: {
      ...process.env,
      HOME: root,
      GEOFFREY_KEYCHAIN_COMMAND: fakeSecurity,
      GEOFFREY_FAKE_KEYCHAIN: keychain,
      GEOFFREY_FAKE_KEYCHAIN_LOG: log,
    },
  };
}

function run(item, source) {
  return execFileSync(process.execPath, ["--input-type=module", "-e", source], {
    env: item.env,
    encoding: "utf8",
  });
}

test("stores OAuth credentials in Keychain while keeping the registry secret-free", () => {
  const item = fixture("geoffrey-keychain-");
  try {
    const result = JSON.parse(run(item, `
      import { readFileSync } from "node:fs";
      import { getAccount, listAccounts, removeAccount, storePath, upsertAccount } from ${JSON.stringify(storeModule)};
      const saved = upsertAccount({
        id: "work", provider: "google", email: "owner@example.com", purpose: "Work",
        client_id: "client-id", client_secret: "client-secret", refresh_token: "refresh-secret",
        scope: "mail calendar", added_at: "2026-10-16T00:00:00.000Z",
      });
      const registryBeforeRemove = JSON.parse(readFileSync(storePath(), "utf8"));
      const hydrated = getAccount("work");
      const listed = listAccounts();
      const removed = removeAccount("work");
      const registryAfterRemove = JSON.parse(readFileSync(storePath(), "utf8"));
      console.log(JSON.stringify({ saved, registryBeforeRemove, hydrated, listed, removed, registryAfterRemove }));
    `));

    assert.equal(result.saved.credential_store, "macos_keychain");
    assert.equal(result.hydrated.refresh_token, "refresh-secret");
    assert.equal(result.hydrated.client_secret, "client-secret");
    assert.equal(result.listed[0].credential_store, "macos_keychain");
    assert.equal(Object.hasOwn(result.listed[0], "refresh_token"), false);
    assert.doesNotMatch(JSON.stringify(result.registryBeforeRemove), /refresh-secret|client-secret|refresh_token|client_secret/);
    assert.deepEqual(result.registryAfterRemove.accounts, []);
    assert.deepEqual(JSON.parse(readFileSync(item.keychain, "utf8")), {});
    const argumentsText = JSON.stringify(JSON.parse(readFileSync(item.log, "utf8")));
    assert.doesNotMatch(argumentsText, /refresh-secret|client-secret/);
    assert.equal(statSync(item.store).mode & 0o777, 0o700);
    assert.equal(statSync(join(item.store, "accounts.json")).mode & 0o777, 0o600);
  } finally {
    rmSync(item.root, { recursive: true, force: true });
  }
});

test("migrates a legacy registry transactionally and scrubs its plaintext backup", () => {
  const item = fixture("geoffrey-keychain-migrate-");
  try {
    const legacy = { accounts: [{
      id: "outlook", provider: "microsoft", email: "owner@example.com", purpose: "Work",
      client_id: "public-client", refresh_token: "legacy-refresh", scope: "Mail.ReadWrite",
      added_at: "2026-10-16T00:00:00.000Z",
    }] };
    const backup = join(item.store, "backups", "pre-desktop-v1", "accounts.json");
    mkdirSync(dirname(backup), { recursive: true });
    writeFileSync(join(item.store, "accounts.json"), JSON.stringify(legacy));
    writeFileSync(backup, JSON.stringify(legacy));

    const result = JSON.parse(run(item, `
      import { getAccount, listAccounts } from ${JSON.stringify(storeModule)};
      console.log(JSON.stringify({ listed: listAccounts(), hydrated: getAccount("outlook") }));
    `));
    assert.equal(result.hydrated.refresh_token, "legacy-refresh");
    assert.equal(result.listed[0].credential_store, "macos_keychain");
    const liveText = readFileSync(join(item.store, "accounts.json"), "utf8");
    const backupText = readFileSync(backup, "utf8");
    assert.doesNotMatch(liveText, /legacy-refresh|refresh_token/);
    assert.doesNotMatch(backupText, /legacy-refresh|refresh_token/);
    assert.match(backupText, /credentials_migrated_to/);
    assert.equal(statSync(backup).mode & 0o777, 0o600);
  } finally {
    rmSync(item.root, { recursive: true, force: true });
  }
});

test("preserves legacy plaintext when Keychain migration cannot complete", () => {
  const item = fixture("geoffrey-keychain-failure-");
  try {
    const legacy = { accounts: [{
      id: "work", provider: "google", email: "owner@example.com", purpose: "Work",
      client_id: "client-id", client_secret: "client-secret", refresh_token: "keep-until-safe",
    }] };
    const backup = join(item.store, "backups", "pre-desktop-v1", "accounts.json");
    mkdirSync(dirname(backup), { recursive: true });
    writeFileSync(join(item.store, "accounts.json"), JSON.stringify(legacy));
    writeFileSync(backup, JSON.stringify(legacy));
    const attempt = spawnSync(process.execPath, ["--input-type=module", "-e", `
      import { listAccounts } from ${JSON.stringify(storeModule)};
      listAccounts();
    `], {
      env: { ...item.env, GEOFFREY_FAKE_KEYCHAIN_FAIL_ADD: "1" },
      encoding: "utf8",
    });
    assert.notEqual(attempt.status, 0);
    const visible = JSON.parse(run({ ...item, env: { ...item.env, GEOFFREY_FAKE_KEYCHAIN_FAIL_ADD: "1" } }, `
      import { listAccountsForStatus } from ${JSON.stringify(storeModule)};
      console.log(JSON.stringify(listAccountsForStatus()));
    `));
    assert.equal(visible[0].credential_store, "migration_pending");
    assert.equal(Object.hasOwn(visible[0], "refresh_token"), false);
    const status = JSON.parse(execFileSync(process.execPath, [accountStatusScript], {
      env: { ...item.env, GEOFFREY_FAKE_KEYCHAIN_FAIL_ADD: "1" }, encoding: "utf8",
    }));
    assert.equal(status[0].credential_state, "needs_reconnect");
    assert.equal(status[0].calendar.state, "needs_reconnect");
    assert.equal(Object.hasOwn(status[0], "refresh_token"), false);
    assert.match(readFileSync(join(item.store, "accounts.json"), "utf8"), /keep-until-safe/);
    assert.match(readFileSync(backup, "utf8"), /keep-until-safe/);
    assert.equal(existsSync(item.keychain), false);
  } finally {
    rmSync(item.root, { recursive: true, force: true });
  }
});

test("rolls back earlier Keychain items when a later account cannot migrate", () => {
  const item = fixture("geoffrey-keychain-rollback-");
  try {
    const legacy = { accounts: [
      {
        id: "first", provider: "google", email: "first@example.com", purpose: "First",
        client_id: "first-client", client_secret: "first-secret", refresh_token: "first-refresh",
      },
      {
        id: "second", provider: "microsoft", email: "second@example.com", purpose: "Second",
        client_id: "second-client", refresh_token: "second-refresh",
      },
    ] };
    mkdirSync(item.store, { recursive: true });
    writeFileSync(join(item.store, "accounts.json"), JSON.stringify(legacy));
    const attempt = spawnSync(process.execPath, ["--input-type=module", "-e", `
      import { listAccounts } from ${JSON.stringify(storeModule)};
      listAccounts();
    `], {
      env: { ...item.env, GEOFFREY_FAKE_KEYCHAIN_FAIL_ACCOUNT: "microsoft:second" },
      encoding: "utf8",
    });
    assert.notEqual(attempt.status, 0);
    assert.match(readFileSync(join(item.store, "accounts.json"), "utf8"), /first-refresh/);
    assert.match(readFileSync(join(item.store, "accounts.json"), "utf8"), /second-refresh/);
    assert.deepEqual(JSON.parse(readFileSync(item.keychain, "utf8")), {});
  } finally {
    rmSync(item.root, { recursive: true, force: true });
  }
});
