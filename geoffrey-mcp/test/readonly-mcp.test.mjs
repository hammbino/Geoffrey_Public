import assert from 'node:assert/strict';
import { mkdtempSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';
import test from 'node:test';
import { Client } from '@modelcontextprotocol/sdk/client/index.js';
import { StdioClientTransport } from '@modelcontextprotocol/sdk/client/stdio.js';

const script = fileURLToPath(new URL('../src/index.js', import.meta.url));
const readTools = ['get_message', 'list_accounts', 'list_calendars', 'list_events', 'list_labels', 'search_messages'];

for (const readOnly of [true, false]) {
  test(`${readOnly ? 'app read-only' : 'normal'} MCP exposes the intended tools`, async () => {
    const home = mkdtempSync(join(tmpdir(), 'geoffrey-mcp-readonly-'));
    const client = new Client({ name: 'readonly-test', version: '1.0.0' });
    const transport = new StdioClientTransport({
      command: process.execPath, args: [script],
      env: { ...process.env, HOME: home, GEOFFREY_READ_ONLY: readOnly ? '1' : '0' },
      stderr: 'pipe',
    });
    try {
      await client.connect(transport);
      const { tools } = await client.listTools();
      const expected = readOnly ? readTools : [...readTools, 'create_draft', 'modify_labels'].sort();
      assert.deepEqual(tools.map(tool => tool.name).sort(), expected);
      for (const tool of tools.filter(tool => readTools.includes(tool.name))) {
        assert.equal(tool.annotations.readOnlyHint, true);
        assert.equal(tool.annotations.destructiveHint, false);
      }
      const accounts = await client.callTool({ name: 'list_accounts', arguments: {} });
      assert.equal(accounts.isError, undefined);
      assert.deepEqual(JSON.parse(accounts.content[0].text).accounts, []);
      if (readOnly) {
        const denied = await client.callTool({ name: 'modify_labels', arguments: {} });
        assert.equal(denied.isError, true);
      }
    } finally {
      await client.close();
      rmSync(home, { recursive: true, force: true });
    }
  });
}
