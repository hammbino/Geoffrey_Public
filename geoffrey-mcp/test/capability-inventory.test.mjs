import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import { chmodSync, mkdtempSync, mkdirSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import test from "node:test";

const here = dirname(fileURLToPath(import.meta.url));
const script = join(here, "../bin/capability-inventory.js");

test("capability inventory combines skills, plugins, and MCPs without account data", () => {
  const root = mkdtempSync(join(tmpdir(), "geoffrey-capabilities-"));
  const engine = join(root, "engine");
  const fakeBin = join(root, "bin");
  try {
    mkdirSync(join(engine, ".claude", "skills", "daily-brief"), { recursive: true });
    mkdirSync(join(root, ".claude", "skills", "personal-workflow"), { recursive: true });
    mkdirSync(fakeBin, { recursive: true });
    writeFileSync(join(engine, ".claude", "skills", "daily-brief", "SKILL.md"), "---\ndescription: Prepare the day\n---\n");
    writeFileSync(join(root, ".claude", "skills", "personal-workflow", "SKILL.md"), "---\ndescription: Owner workflow\n---\n");
    writeFileSync(join(fakeBin, "claude"), `#!/usr/bin/env bash\nif [ "$1" = "plugin" ]; then echo '[{"id":"social@market","enabled":true,"scope":"user"}]'; else echo 'geoffrey: connected'; fi\n`);
    chmodSync(join(fakeBin, "claude"), 0o755);
    const output = execFileSync("node", [script, "--engine-root", engine], { env: { ...process.env, HOME: root, PATH: `${fakeBin}:${process.env.PATH}` }, encoding: "utf8" });
    const result = JSON.parse(output);
    assert.deepEqual(result.map(({ id }) => id), ["mcp:geoffrey", "plugin:social@market", "skill:daily-brief", "skill:personal-workflow"]);
    assert.equal(result.find(({ id }) => id === "skill:personal-workflow").source, "Claude account");
  } finally {
    rmSync(root, { recursive: true, force: true });
  }
});
