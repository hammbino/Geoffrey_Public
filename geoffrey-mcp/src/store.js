// Secret-free account registry with macOS Keychain-backed OAuth credentials.
//
// ~/.geoffrey/accounts.json contains only labels and connection metadata. The
// refresh token, OAuth client id, optional client secret, and scope are stored
// as one versioned generic-password item per account in the login Keychain.

import { spawnSync } from "node:child_process";
import {
  chmodSync,
  existsSync,
  mkdirSync,
  readFileSync,
  renameSync,
  rmSync,
  writeFileSync,
} from "node:fs";
import { homedir } from "node:os";
import { dirname, join } from "node:path";

const DIR = join(homedir(), ".geoffrey");
const FILE = join(DIR, "accounts.json");
const LEGACY_BACKUP = join(DIR, "backups", "pre-desktop-v1", "accounts.json");
const KEYCHAIN_SERVICE = "com.geoffrey.desktop.oauth.v1";
const KEYCHAIN_COMMAND = process.env.GEOFFREY_KEYCHAIN_COMMAND || "/usr/bin/security";
const SECRET_FIELDS = ["client_id", "client_secret", "refresh_token", "scope"];

function keychainAccount(account) {
  return `${account.provider}:${account.id}`;
}

function runKeychain(parameters, input = undefined) {
  const result = spawnSync(KEYCHAIN_COMMAND, parameters, {
    encoding: "utf8",
    input,
    stdio: ["pipe", "pipe", "pipe"],
    timeout: 15_000,
    maxBuffer: 1024 * 1024,
  });
  if (result.error?.code === "ENOENT") {
    throw new Error("macOS Keychain is unavailable. Reopen Geoffrey on a Mac and try again.");
  }
  if (result.error?.code === "ETIMEDOUT" || result.signal === "SIGTERM") {
    throw new Error("macOS Keychain did not respond. Unlock this Mac and try again.");
  }
  return result;
}

function readCredential(account) {
  const result = runKeychain([
    "find-generic-password",
    "-s", KEYCHAIN_SERVICE,
    "-a", keychainAccount(account),
    "-w",
  ]);
  if (result.status === 44) return null;
  if (result.status !== 0) throw new Error(`Geoffrey could not read the Keychain credential for "${account.id}". Reconnect this account.`);
  try {
    const value = JSON.parse(result.stdout);
    if (value.schema_version !== 1 || value.id !== account.id || value.provider !== account.provider
        || typeof value.client_id !== "string" || typeof value.refresh_token !== "string") {
      throw new Error("invalid credential payload");
    }
    return value;
  } catch {
    throw new Error(`The Keychain credential for "${account.id}" is invalid. Reconnect this account.`);
  }
}

function writeCredential(account, credential) {
  const value = JSON.stringify({
    schema_version: 1,
    id: account.id,
    provider: account.provider,
    client_id: credential.client_id,
    ...(credential.client_secret ? { client_secret: credential.client_secret } : {}),
    refresh_token: credential.refresh_token,
    ...(credential.scope ? { scope: credential.scope } : {}),
  });
  const result = runKeychain([
    "add-generic-password",
    "-U",
    "-s", KEYCHAIN_SERVICE,
    "-a", keychainAccount(account),
    "-l", `Geoffrey ${account.id} ${account.provider} OAuth`,
    // With -w as the final option, macOS reads the password from stdin instead
    // of exposing it in this process's command-line arguments.
    "-w",
    // A new generic-password item asks for the value and a confirmation. Updates
    // consume the first line and ignore the second, so the same non-argv input is
    // safe for both create and replace.
  ], value + "\n" + value + "\n");
  if (result.status !== 0) throw new Error(`Geoffrey could not save the credential for "${account.id}" in macOS Keychain.`);
}

function deleteCredential(account) {
  const result = runKeychain([
    "delete-generic-password",
    "-s", KEYCHAIN_SERVICE,
    "-a", keychainAccount(account),
  ]);
  if (result.status !== 0 && result.status !== 44) {
    throw new Error(`Geoffrey could not remove the Keychain credential for "${account.id}".`);
  }
}

function credentialFrom(account) {
  if (!SECRET_FIELDS.some((field) => Object.hasOwn(account, field))) return null;
  if (typeof account.client_id !== "string" || !account.client_id
      || typeof account.refresh_token !== "string" || !account.refresh_token) {
    throw new Error(`The stored credential for "${account.id}" is incomplete. Reconnect this account.`);
  }
  return Object.fromEntries(SECRET_FIELDS.flatMap((field) => (
    typeof account[field] === "string" && account[field] ? [[field, account[field]]] : []
  )));
}

function metadataFrom(account) {
  const metadata = { ...account, credential_store: "macos_keychain" };
  for (const field of SECRET_FIELDS) delete metadata[field];
  return metadata;
}

function secretFree(data) {
  return !data.accounts.some((account) => SECRET_FIELDS.some((field) => Object.hasOwn(account, field)));
}

function readRegistry(path = FILE) {
  if (!existsSync(path)) return { accounts: [] };
  const data = JSON.parse(readFileSync(path, "utf8"));
  if (!Array.isArray(data.accounts)) throw new Error("The Geoffrey account registry is invalid.");
  return data;
}

function atomicRegistry(path, data) {
  if (!secretFree(data)) throw new Error("Refusing to write account credentials outside macOS Keychain.");
  mkdirSync(dirname(path), { recursive: true, mode: 0o700 });
  chmodSync(dirname(path), 0o700);
  const temporary = `${path}.tmp-${process.pid}`;
  try {
    writeFileSync(temporary, JSON.stringify(data, null, 2) + "\n", { mode: 0o600 });
    chmodSync(temporary, 0o600);
    renameSync(temporary, path);
    chmodSync(path, 0o600);
  } finally {
    if (existsSync(temporary)) rmSync(temporary, { force: true });
  }
}

function scrubLegacyBackup() {
  if (!existsSync(LEGACY_BACKUP)) return;
  const data = readRegistry(LEGACY_BACKUP);
  if (secretFree(data)) return;
  atomicRegistry(LEGACY_BACKUP, {
    ...data,
    accounts: data.accounts.map(metadataFrom),
    credentials_migrated_to: "macos_keychain",
  });
}

function migrateLegacyRegistry(data) {
  const legacy = data.accounts.filter((account) => credentialFrom(account));
  if (!legacy.length) {
    if (data.credential_storage_version === 1) scrubLegacyBackup();
    return data;
  }

  const rollback = [];
  let migrated;
  try {
    for (const account of legacy) {
      const previous = readCredential(account);
      rollback.push({ account, previous });
      writeCredential(account, credentialFrom(account));
    }
    migrated = {
      ...data,
      accounts: data.accounts.map(metadataFrom),
      credential_storage_version: 1,
    };
    atomicRegistry(FILE, migrated);
  } catch (error) {
    for (const { account, previous } of rollback.reverse()) {
      try {
        if (previous) writeCredential(account, previous);
        else deleteCredential(account);
      } catch {
        // Preserve the original migration error. A repeated migration safely
        // replaces any partial Keychain item because writes use -U.
      }
    }
    throw error;
  }
  // The live registry and Keychain now agree. Backup cleanup is deliberately
  // outside the rollback block: a cleanup failure must never delete the new
  // Keychain items after the plaintext registry has already been scrubbed.
  scrubLegacyBackup();
  return migrated;
}

export function storePath() {
  return FILE;
}

export function credentialStoreName() {
  return "macOS Keychain";
}

export function load() {
  return migrateLegacyRegistry(readRegistry());
}

export function save(data) {
  atomicRegistry(FILE, data);
}

export function listAccounts() {
  return load().accounts.map(({ id, provider, email, purpose, added_at, credential_store }) => ({
    id, provider, email, purpose, added_at, credential_store,
  }));
}

export function listAccountsForStatus() {
  try {
    return listAccounts();
  } catch {
    // Keep legacy accounts visible in the repair UI if Keychain migration is
    // temporarily unavailable. This never returns any credential fields.
    return readRegistry().accounts.map((account) => ({
      ...metadataFrom(account),
      credential_store: "migration_pending",
    }));
  }
}

// Throws rather than defaulting. Omitting the account is an error, never a
// guess about which mailbox the owner meant.
export function getAccount(id) {
  if (!id) {
    throw new Error(
      "No account specified. Every tool needs an explicit account id. " +
      "Call list_accounts to see what is connected."
    );
  }
  const data = load();
  const found = data.accounts.find((account) => account.id === id);
  if (!found) {
    const known = data.accounts.map((account) => account.id).join(", ") || "none";
    throw new Error(`Unknown account "${id}". Connected accounts: ${known}`);
  }
  const credential = readCredential(found);
  if (!credential) throw new Error(`The Keychain credential for "${id}" is missing. Reconnect this account.`);
  return { ...found, ...credential };
}

export function upsertAccount(account) {
  const data = load();
  const index = data.accounts.findIndex((item) => item.id === account.id);
  const previousAccount = index >= 0 ? data.accounts[index] : null;
  const merged = { ...(previousAccount ?? {}), ...account };
  const credential = credentialFrom(merged);
  if (!credential) throw new Error(`No OAuth credential was provided for "${account.id}".`);
  const previousCredential = previousAccount ? readCredential(previousAccount) : null;
  const nextMetadata = metadataFrom(merged);

  writeCredential(nextMetadata, credential);
  try {
    if (index >= 0) data.accounts[index] = nextMetadata;
    else data.accounts.push(nextMetadata);
    data.credential_storage_version = 1;
    atomicRegistry(FILE, data);
  } catch (error) {
    try {
      if (previousCredential) writeCredential(previousAccount, previousCredential);
      else deleteCredential(nextMetadata);
    } catch {
      // Keep the registry error as the primary failure; the next upsert uses -U.
    }
    throw error;
  }
  if (previousAccount && keychainAccount(previousAccount) !== keychainAccount(nextMetadata)) {
    try { deleteCredential(previousAccount); } catch { /* old item contains no new credential */ }
  }
  return nextMetadata;
}

export function removeAccount(id) {
  const data = load();
  const index = data.accounts.findIndex((account) => account.id === id);
  if (index < 0) throw new Error(`Unknown account "${id}".`);
  const account = data.accounts[index];
  const previousCredential = readCredential(account);
  deleteCredential(account);
  data.accounts.splice(index, 1);
  try {
    atomicRegistry(FILE, data);
  } catch (error) {
    if (previousCredential) {
      try { writeCredential(account, previousCredential); } catch { /* surface registry error */ }
    }
    throw error;
  }
  return account;
}
