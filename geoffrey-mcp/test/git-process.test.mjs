import test from "node:test";
import assert from "node:assert/strict";
import { mkdtempSync, mkdirSync, writeFileSync, readFileSync, existsSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { spawnGit } from "../src/git-process.js";

test("GitHub operations use gh without inherited Keychain helpers or persistent config changes", () => {
  const root = mkdtempSync(join(tmpdir(), "geoffrey-git-auth-"));
  try {
    const bin = join(root, "bin"); mkdirSync(bin);
    const config = '[credential]\n helper = !touch "$HOME/unwanted-keychain"\n[credential "https://github.com"]\n helper = !touch "$HOME/unwanted-keychain"\n';
    writeFileSync(join(root, ".gitconfig"), config);
    writeFileSync(join(bin, "gh"), `#!/bin/sh
test "$1 $2 $3" = "auth git-credential get" || exit 1
test "$GIT_TERMINAL_PROMPT $GH_PROMPT_DISABLED" = "0 1" || exit 2
cat > "$HOME/credential-request"
printf 'username=fixture\\npassword=dummy-test-value\\n'
`, { mode: 0o700 });
    const env = { ...process.env, HOME: root, PATH: bin + ":" + process.env.PATH, GIT_CONFIG_GLOBAL: join(root, ".gitconfig"), GIT_CONFIG_NOSYSTEM: "1" };
    const result = spawnGit(["credential", "fill"], { env, input: "protocol=https\nhost=github.com\n\n", encoding: "utf8", timeout: 5000 });
    assert.equal(result.status, 0, result.stderr);
    assert.match(result.stdout, /username=fixture/);
    assert.equal(existsSync(join(root, "unwanted-keychain")), false);
    assert.match(readFileSync(join(root, "credential-request"), "utf8"), /host=github.com/);
    assert.equal(readFileSync(join(root, ".gitconfig"), "utf8"), config);
    rmSync(join(root, "credential-request"));
    const other = spawnGit(["credential", "fill"], { env, input: "protocol=https\nhost=unrelated.example\n\n", encoding: "utf8", timeout: 5000 });
    assert.notEqual(other.status, 0);
    assert.equal(existsSync(join(root, "credential-request")), false, "GitHub credential helper is scoped to github.com");
    assert.equal(existsSync(join(root, "unwanted-keychain")), false);
  } finally { rmSync(root, { recursive: true, force: true }); }
});
