import assert from 'node:assert/strict';
import { mkdtempSync, mkdirSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';
import test from 'node:test';
import { buildAutomationInventory } from '../src/automation-inventory.js';

const script = fileURLToPath(new URL('../bin/automation-remove.js', import.meta.url));
function fixture() {
  const root = mkdtempSync(join(tmpdir(), 'geoffrey-remove-'));
  const memory = join(root, 'memory-repo');
  const store = join(root, '.geoffrey');
  mkdirSync(join(memory, 'memory/automations'), { recursive: true });
  mkdirSync(join(store, 'automations'), { recursive: true });
  writeFileSync(join(store, 'current-memory'), memory);
  const migration = { private_state: { memory_repository: { automation_candidates: ['memory/social-briefing.md'] } } };
  writeFileSync(join(store, 'migration-v1.json'), JSON.stringify(migration));
  const manifest = join(memory, 'memory/automations/manifest.json');
  const workflow = { id: 'social-test', name: 'Social test', enabled: true, task: 'Prepare a summary', approval: { state: 'approved' }, execution: { preference: 'local' }, source: { kind: 'user_created' } };
  writeFileSync(manifest, JSON.stringify({ schema_version: 1, workflows: [workflow] }));
  writeFileSync(join(memory, 'memory/automations/history.json'), '{"runs":[]}');
  writeFileSync(join(memory, 'memory/briefing-reactions.json'), 'feedback must stay');
  return { root, store, memory, manifest, migration, workflow };
}
function remove(f, id, ...flags) {
  return spawnSync('node', [script, '--workflow', id, ...flags], { env: { ...process.env, HOME: f.root }, encoding: 'utf8' });
}
test('removal keeps feedback/history and prevents a dismissed import from returning', () => {
  const f = fixture();
  try {
    assert.equal(remove(f, 'social-test').status, 0);
    let manifest = JSON.parse(readFileSync(f.manifest, 'utf8'));
    assert.equal(manifest.workflows.length, 0);
    assert.equal(manifest.removed_workflows[0].workflow.task, 'Prepare a summary');
    const imported = buildAutomationInventory({ manifest, migration: f.migration }).workflows[0];
    assert.equal(remove(f, imported.id).status, 0);
    manifest = JSON.parse(readFileSync(f.manifest, 'utf8'));
    assert.equal(buildAutomationInventory({ manifest, migration: f.migration }).workflows.length, 0);
    assert.equal(readFileSync(join(f.memory, 'memory/briefing-reactions.json'), 'utf8'), 'feedback must stay');
    assert.equal(readFileSync(join(f.memory, 'memory/automations/history.json'), 'utf8'), '{"runs":[]}');
  } finally { rmSync(f.root, { recursive: true, force: true }); }
});
test('connected cloud schedules require explicit stop confirmation and running work cannot be removed', () => {
  const f = fixture();
  try {
    f.workflow.execution = { preference: 'cloud', routine_url: 'https://claude.ai/scheduled-task/trig_test' };
    f.workflow.requirements = { cloud_compatible: true };
    writeFileSync(f.manifest, JSON.stringify({ schema_version: 1, workflows: [f.workflow] }));
    const before = readFileSync(f.manifest, 'utf8');
    assert.notEqual(remove(f, 'social-test').status, 0);
    assert.equal(readFileSync(f.manifest, 'utf8'), before);
    writeFileSync(join(f.store, 'automations/run.lock'), 'busy');
    assert.notEqual(remove(f, 'social-test', '--cloud-stopped').status, 0);
    rmSync(join(f.store, 'automations/run.lock'));
    assert.notEqual(remove(f, '../escape').status, 0);
    assert.equal(remove(f, 'social-test', '--cloud-stopped').status, 0);
  } finally { rmSync(f.root, { recursive: true, force: true }); }
});
