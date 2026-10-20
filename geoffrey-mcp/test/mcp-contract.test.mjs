import assert from "node:assert/strict";
import { mkdtempSync, mkdirSync, writeFileSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import test from "node:test";

import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import { StdioClientTransport } from "@modelcontextprotocol/sdk/client/stdio.js";

const here = dirname(fileURLToPath(import.meta.url));
const packageRoot = join(here, "..");

test("read-only reader lists all five Geoffrey accounts across Google and Microsoft", async () => {
  const home = mkdtempSync(join(tmpdir(), "geoffrey-five-accounts-"));
  const accounts = Array.from({ length: 5 }, (_, index) => ({ id: `account-${index}`, provider: index < 3 ? "google" : "microsoft", email: `owner${index}@example.test`, credential_store: "macos_keychain", credential_key: `fixture-${index}` }));
  mkdirSync(join(home, ".geoffrey"));
  writeFileSync(join(home, ".geoffrey", "accounts.json"), JSON.stringify({ credential_storage_version: 1, accounts }));
  const client = new Client({ name: "geoffrey-test", version: "1.0.0" });
  try {
    await client.connect(new StdioClientTransport({ command: "node", args: [join(packageRoot, "src/index.js")], env: { ...process.env, HOME: home, GEOFFREY_READ_ONLY: "1" } }));
    const listed = await client.callTool({ name: "list_accounts", arguments: {} });
    const actual = JSON.parse(listed.content[0].text).accounts;
    assert.equal(actual.length, 5);
    assert.deepEqual(actual.map(item => item.id), accounts.map(item => item.id));
    assert.equal(actual.filter(item => item.provider === "microsoft").length, 2);
    assert.equal(JSON.stringify(actual).includes("credential_key"), false);
  } finally { await client.close(); rmSync(home, { recursive: true, force: true }); }
});

test("MCP exposes the multi-account contract without real credentials", async () => {
  const fixtureHome = mkdtempSync(join(tmpdir(), "geoffrey-mcp-test-"));
  const transport = new StdioClientTransport({
    command: "node",
    args: [join(packageRoot, "src/index.js")],
    env: { ...process.env, HOME: fixtureHome },
  });
  const client = new Client({ name: "geoffrey-test", version: "1.0.0" });

  try {
    await client.connect(transport);

    const { tools } = await client.listTools();
    assert.deepEqual(
      tools.map((tool) => tool.name).sort(),
      [
        "create_draft",
        "get_message",
        "list_accounts",
        "list_calendars",
        "list_events",
        "list_labels",
        "modify_labels",
        "search_messages",
      ]
    );

    const listed = await client.callTool({ name: "list_accounts", arguments: {} });
    assert.equal(listed.isError, undefined);
    assert.deepEqual(JSON.parse(listed.content[0].text).accounts, []);

    const omitted = await client.callTool({
      name: "search_messages",
      arguments: { query: "invoice" },
    });
    assert.equal(omitted.isError, true);

    const unknown = await client.callTool({
      name: "search_messages",
      arguments: { account: "missing", query: "invoice" },
    });
    assert.equal(unknown.isError, true);
    assert.match(unknown.content[0].text, /Unknown account/);
  } finally {
    await client.close();
    rmSync(fixtureHome, { recursive: true, force: true });
  }
});
