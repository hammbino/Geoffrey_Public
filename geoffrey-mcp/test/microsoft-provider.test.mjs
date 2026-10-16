import assert from "node:assert/strict";
import test from "node:test";

import * as microsoft from "../src/providers/microsoft.js";

const account = {
  id: "outlook",
  provider: "microsoft",
  email: "owner@example.com",
  client_id: "client-id",
  refresh_token: "refresh-token",
  scope: "Mail.ReadWrite Calendars.Read",
};

function installGraphMock() {
  const calls = [];
  const originalFetch = globalThis.fetch;
  globalThis.fetch = async (input, options = {}) => {
    const url = typeof input === "string" ? input : input.toString();
    if (url.includes("oauth2")) {
      return new Response(JSON.stringify({ access_token: "test-token", expires_in: 3600 }), { status: 200 });
    }

    calls.push({
      url: decodeURIComponent(url),
      method: options.method ?? "GET",
      body: options.body,
    });
    const path = new URL(url).pathname;
    if (path.endsWith("/messages") && (options.method ?? "GET") === "GET") {
      return new Response(JSON.stringify({ value: [] }), { status: 200 });
    }
    if (path.endsWith("/mailFolders")) {
      return new Response(JSON.stringify({ value: [{ id: "inbox", displayName: "Inbox" }] }), { status: 200 });
    }
    if (path.includes("masterCategories")) return new Response("forbidden", { status: 403 });
    if (path.includes("/messages/") && (options.method ?? "GET") === "GET") {
      return new Response(JSON.stringify({ categories: ["Existing"] }), { status: 200 });
    }
    return new Response(JSON.stringify({ id: "result", value: [] }), { status: 200 });
  };
  return { calls, restore: () => { globalThis.fetch = originalFetch; } };
}

test("structured Outlook search uses filters and never combines them with search", async () => {
  const mock = installGraphMock();
  try {
    await microsoft.searchMessages(account, {
      unread_only: true,
      newer_than_days: 7,
      from_address: "sender@example.com",
      limit: 5,
    });
    const request = mock.calls.at(-1);
    assert.equal(request.method, "GET");
    assert.match(request.url, /\$filter=/);
    assert.match(request.url, /isRead eq false/);
    assert.match(request.url, /receivedDateTime ge/);
    assert.match(request.url, /sender@example\.com/);
    assert.doesNotMatch(request.url, /\$search=/);
  } finally {
    mock.restore();
  }
});

test("free-text Outlook search does not add incompatible filter or ordering", async () => {
  const mock = installGraphMock();
  try {
    await microsoft.searchMessages(account, { query: "invoice", limit: 5 });
    const request = mock.calls.at(-1);
    assert.match(request.url, /\$search="invoice"/);
    assert.doesNotMatch(request.url, /\$filter=/);
    assert.doesNotMatch(request.url, /\$orderby=/);
  } finally {
    mock.restore();
  }
});

test("Outlook label changes remain drafts of state and do not send mail", async () => {
  const mock = installGraphMock();
  try {
    const result = await microsoft.modifyLabels(account, {
      message_id: "message-1",
      add: ["Urgent"],
      remove: ["UNREAD"],
    });
    const patch = mock.calls.find((call) => call.method === "PATCH");
    assert.deepEqual(JSON.parse(patch.body), {
      isRead: true,
      categories: ["Existing", "Urgent"],
    });
    assert.equal(result.archived, false);
    assert.equal(mock.calls.some((call) => /\/send$/.test(new URL(call.url).pathname)), false);
  } finally {
    mock.restore();
  }
});

test("missing Outlook category scope degrades to folders", async () => {
  const mock = installGraphMock();
  try {
    const result = await microsoft.listLabels(account);
    assert.deepEqual(result.labels, [{ id: "inbox", name: "Inbox", type: "folder" }]);
    assert.match(result.note, /Categories unavailable/);
  } finally {
    mock.restore();
  }
});
