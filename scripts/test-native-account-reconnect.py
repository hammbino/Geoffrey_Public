#!/usr/bin/env python3
"""Explicit dummy-only reconnect + status proof. Never permits Keychain UI."""
import json
import os
import pathlib
import subprocess
import sys
import tempfile

root = pathlib.Path(__file__).resolve().parent.parent
helper = str(pathlib.Path(sys.argv[1]).resolve())
keychain_home = os.environ["HOME"]
with tempfile.TemporaryDirectory(prefix="geoffrey-native-reconnect-") as work:
    home = pathlib.Path(work)
    log = home / "keys.jsonl"
    wrapper = home / "keychain"
    errors = home / "helper-errors.txt"
    wrapper.write_text(f"""#!/usr/bin/env python3
import json,os,sys,subprocess
args=sys.argv[1:]
key=args[args.index('-a')+1]
assert key.startswith('google:native-reconnect-')
with open({str(log)!r}, 'a') as f: f.write(json.dumps(key)+'\\n')
os.environ['HOME']={keychain_home!r}
result=subprocess.run([{helper!r}, *args, '--no-ui'], input=sys.stdin.buffer.read(), capture_output=True)
if result.stderr:
    with open({str(errors)!r}, 'ab') as f: f.write(result.stderr)
sys.stdout.buffer.write(result.stdout)
sys.exit(result.returncode)
""")
    wrapper.chmod(0o700)
    mock = home / "mock-provider.mjs"
    mock.write_text('''globalThis.fetch = async (input) => {
      const url = new URL(input);
      let value;
      if (url.origin === "https://oauth2.googleapis.com" && url.pathname === "/token") value = { access_token: "dummy-access", expires_in: 3600 };
      else if (url.origin === "https://gmail.googleapis.com" && url.pathname.endsWith("/profile")) value = { emailAddress: "fixture@example.test" };
      else if (url.origin === "https://www.googleapis.com" && url.pathname.endsWith("/events")) value = { items: [] };
      else throw new Error("Unexpected provider operation; no network request was made");
      return new Response(JSON.stringify(value), { status: 200 });
    };''')
    source = '''
      import assert from "node:assert/strict";
      import { randomUUID } from "node:crypto";
      import { spawnSync } from "node:child_process";
      import { upsertAccount, getAccount, removeAccount, listAccounts } from __STORE__;
      const account = { id: "native-reconnect-" + randomUUID(), provider: "google", email: "fixture@example.test", client_id: "dummy-client", refresh_token: "dummy-old" };
      const old = upsertAccount(account);
      const damaged = spawnSync(process.env.GEOFFREY_KEYCHAIN_COMMAND, ["add-generic-password", "-U", "-s", "com.geoffrey.desktop.oauth.v1", "-a", old.credential_key, "-w"], { input: '{"damaged":', encoding: "utf8" });
      assert.equal(damaged.status, 0);
      const updated = upsertAccount({ ...account, refresh_token: "dummy-refresh-".repeat(2000) });
      assert.notEqual(updated.credential_key, old.credential_key);
      assert.equal(getAccount(account.id).refresh_token, "dummy-refresh-".repeat(2000));
      const status = spawnSync(process.execPath, ["--import", __MOCK__, __STATUS__], { env: process.env, encoding: "utf8", timeout: 15000 });
      assert.equal(status.status, 0, "Account status process failed");
      const result = JSON.parse(status.stdout)[0];
      assert.equal(result.credential_state, "ready");
      assert.equal(result.mail.state, "ready");
      assert.equal(result.calendar.state, "ready");
      removeAccount(account.id);
      assert.equal(listAccounts().length, 0);
      console.log("damaged_reconnect_long_read_status_remove=passed");
    '''.replace("__STORE__", json.dumps((root / "geoffrey-mcp/src/store.js").as_uri())).replace("__MOCK__", json.dumps(str(mock))).replace("__STATUS__", json.dumps(str(root / "geoffrey-mcp/bin/account-status.js")))
    env = {**os.environ, "HOME": str(home), "GEOFFREY_KEYCHAIN_COMMAND": str(wrapper)}
    try:
        result = subprocess.run(["node", "--input-type=module", "-e", source], env=env, capture_output=True, text=True, timeout=45)
        if result.returncode:
            raise RuntimeError("Native reconnect/status proof failed; no real account was accessed. " + (errors.read_text() if errors.exists() else "") + result.stderr)
        print(result.stdout.strip())
    finally:
        keys = set(json.loads(line) for line in log.read_text().splitlines()) if log.exists() else set()
        for key in keys:
            assert key.startswith("google:native-reconnect-")
            cleanup = subprocess.run([helper, "delete-generic-password", "--no-ui", "-s", "com.geoffrey.desktop.oauth.v1", "-a", key], capture_output=True, timeout=10)
            assert cleanup.returncode in (0, 44), "Dummy item cleanup failed"
        print("dummy_item_cleanup=passed")
