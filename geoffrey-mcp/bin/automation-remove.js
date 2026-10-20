#!/usr/bin/env node

// Removes Geoffrey's definition, retaining its source and result history.
import { closeSync, existsSync, mkdirSync, openSync, readFileSync, renameSync, unlinkSync, writeFileSync } from 'node:fs';
import { homedir } from 'node:os';
import { join } from 'node:path';
import { buildAutomationInventory } from '../src/automation-inventory.js';

const args = process.argv.slice(2);
const id = args[args.indexOf('--workflow') + 1];
const store = join(homedir(), '.geoffrey');
let lock, lockPath;
function read(path, fallback) {
  if (!existsSync(path)) return fallback;
  try { return JSON.parse(readFileSync(path, 'utf8')); }
  catch { throw new Error('Saved automation data could not be read. Nothing was removed.'); }
}
try {
  if (!args.includes('--workflow') || !/^[a-z0-9][a-z0-9._-]{2,83}$/.test(id ?? '')) throw new Error('Choose an automation to delete.');
  const memory = readFileSync(join(store, 'current-memory'), 'utf8').split(/\r?\n/)[0].trim();
  if (!memory || !existsSync(join(memory, 'memory'))) throw new Error('Private Geoffrey memory is not ready.');
  const directory = join(memory, 'memory', 'automations');
  const path = join(directory, 'manifest.json');
  mkdirSync(join(store, 'automations'), { recursive: true, mode: 0o700 });
  lockPath = join(store, 'automations', 'run.lock');
  try { lock = openSync(lockPath, 'wx', 0o600); }
  catch { throw new Error('An automation is running. Let it finish before deleting recurring work.'); }
  const manifest = read(path, { schema_version: 1, workflows: [] });
  if (!Array.isArray(manifest.workflows) || (manifest.schema_version !== undefined && manifest.schema_version !== 1)) throw new Error('Saved automations have an unsupported format. Nothing was removed.');
  const migration = read(join(store, 'migration-v1.json'), null);
  const inventory = buildAutomationInventory({ manifest, migration });
  const workflow = inventory.workflows.find(item => item.id === id);
  if (!workflow) throw new Error('That automation is no longer in the list. Refresh recurring work.');
  if (workflow.execution.routine_url && !args.includes('--cloud-stopped')) throw new Error('Pause or delete the connected Claude schedule first, then confirm it is stopped.');
  const original = manifest.workflows.find(item => item.id === id) ?? null;
  const removed = Array.isArray(manifest.removed_workflows) ? manifest.removed_workflows : [];
  const next = { ...manifest, schema_version: 1,
    workflows: manifest.workflows.filter(item => item.id !== id),
    removed_workflows: [...removed.filter(item => item.id !== id), { id, source: workflow.source, workflow: original, removed_at: new Date().toISOString() }],
  };
  mkdirSync(directory, { recursive: true, mode: 0o700 });
  writeFileSync(path + '.removing', JSON.stringify(next, null, 2) + '\n', { mode: 0o600 });
  renameSync(path + '.removing', path);
  console.log(JSON.stringify({ ok: true, workflow_id: id }));
} catch (error) {
  console.log(JSON.stringify({ ok: false, error: error.message || 'The automation could not be removed.' }));
  process.exitCode = 1;
} finally {
  if (lock !== undefined) { closeSync(lock); try { unlinkSync(lockPath); } catch {} }
}
