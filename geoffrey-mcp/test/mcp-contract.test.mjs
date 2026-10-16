import assert from "node:assert/strict";
import { mkdtempSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import test from "node:test";

import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import { StdioClientTransport } from "@modelcontextprotocol/sdk/client/stdio.js";

const here = dirname(fileURLToPath(import.meta.url));
const packageRoot = join(here, "..");

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
