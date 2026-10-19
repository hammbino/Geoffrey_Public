import test from "node:test";
import assert from "node:assert/strict";
import { resolveAccountIdentity } from "../src/account-identity.js";

const resolve = (overrides = {}) => resolveAccountIdentity({ provider: "google", email: "Owner@Example.test", accounts: [], ...overrides });
const saved = { id: "Work", provider: "google", email: "owner@example.test", purpose: "Clients" };

test("new desktop connections use the provider email without a label or purpose prompt", () => {
  assert.deepEqual(resolve(), { id: "owner@example.test", purpose: "" });
});
test("connecting the same mailbox again retains its alias and purpose", () => {
  assert.deepEqual(resolve({ accounts: [saved] }), { id: "Work", purpose: "Clients" });
});
test("reconnecting preserves an explicit alias and rejects the wrong signed-in identity", () => {
  assert.deepEqual(resolve({ accounts: [saved], id: "Work", expectedEmail: saved.email }), { id: "Work", purpose: "Clients" });
  assert.throws(() => resolve({ accounts: [saved], id: "Work", expectedEmail: saved.email, email: "other@example.test" }), /different email/);
  assert.throws(() => resolve({ accounts: [saved], id: "Work", provider: "microsoft" }), /different mailbox/);
});
test("automatic names cannot overwrite another provider or an unrelated alias", () => {
  const accounts = [
    { id: "owner@example.test", provider: "microsoft", email: "owner@example.test" },
    { id: "owner@example.test (google 2)", provider: "google", email: "other@example.test" },
  ];
  assert.deepEqual(resolve({ accounts }), { id: "owner@example.test (google 3)", purpose: "" });
});
test("manual CLI labels and purpose remain supported", () => {
  assert.deepEqual(resolve({ id: "Personal", purpose: "Family" }), { id: "Personal", purpose: "Family" });
  assert.throws(() => resolve({ accounts: [saved], id: "Work", email: "other@example.test" }), /different mailbox/);
});
test("missing or invalid provider identity cannot become a saved account", () => {
  for (const email of [undefined, "", "   ", "not-an-address"]) {
    assert.throws(() => resolve({ email }), /did not identify/);
  }
});

test("many Google and Microsoft accounts remain distinct and reconnect targets only the selected mailbox", () => {
  const accounts = [];
  for (let index = 0; index < 100; index++) {
    const provider = index % 2 ? "microsoft" : "google";
    const email = `mailbox${index}@example.test`;
    const identity = resolveAccountIdentity({ provider, email, accounts });
    accounts.push({ ...identity, provider, email });
  }
  assert.equal(new Set(accounts.map(account => account.id)).size, 100);
  const original = structuredClone(accounts);
  const target = accounts[57];
  assert.equal(resolveAccountIdentity({ ...target, expectedEmail: target.email, accounts }).id, target.id);
  assert.deepEqual(accounts, original);
});
