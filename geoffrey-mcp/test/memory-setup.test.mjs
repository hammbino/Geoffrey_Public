import test from "node:test";
import assert from "node:assert/strict";
import { spawnSync, execFileSync } from "node:child_process";
import { mkdtempSync, mkdirSync, readFileSync, rmSync, writeFileSync, statSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { fileURLToPath } from "node:url";

const script = fileURLToPath(new URL("../../bin/geoffrey", import.meta.url));

for (const failBackup of [true, false]) {
  test(`memory becomes selected before GitHub backup ${failBackup ? "fails" : "succeeds"}`, () => {
    const home = mkdtempSync(join(tmpdir(), "geoffrey-memory-setup-"));
    try {
      const bin = join(home, "bin");
      mkdirSync(bin);
      // A fake publisher checks the pointer at the exact remote-operation boundary.
      writeFileSync(join(bin, "gh"), `#!/bin/sh\nif [ "$1" = auth ]; then exit 0; fi\nif [ "$1" = repo ]; then\n  test "$(cat "$HOME/.geoffrey/current-memory")" = "$HOME/Geoffrey" || exit 97\n  touch "$HOME/backup-attempted"\n  exit ${failBackup ? 1 : 0}\nfi\nexit 2\n`, { mode: 0o700 });
      const result = spawnSync(script, ["memory", "--name", "Fixture Owner", "--business", "Personal", "--github", "fixture", "--push"], {
        env: { ...process.env, HOME: home, PATH: `${bin}:${process.env.PATH}`, LC_ALL: "C", GIT_CONFIG_NOSYSTEM: "1", GIT_CONFIG_GLOBAL: "/dev/null" },
        encoding: "utf8", input: "", timeout: 15000,
      });
      assert.doesNotMatch(result.stderr, /What business or team/);
      assert.equal(result.status, failBackup ? 1 : 0, result.stderr || result.stdout);
      assert.equal(readFileSync(join(home, ".geoffrey/current-memory"), "utf8"), join(home, "Geoffrey") + "\n");
      assert.equal(statSync(join(home, ".geoffrey/current-memory")).mode & 0o777, 0o600);
      assert.ok(statSync(join(home, "backup-attempted")).isFile());
      assert.ok(statSync(join(home, "Geoffrey/memory/user.md")).isFile());
      assert.ok(execFileSync("git", ["-C", join(home, "Geoffrey"), "rev-parse", "HEAD"], { encoding: "utf8" }).trim());
    } finally {
      rmSync(home, { recursive: true, force: true });
    }
  });
}
