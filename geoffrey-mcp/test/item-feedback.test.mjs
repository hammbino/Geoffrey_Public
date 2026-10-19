import assert from 'node:assert/strict';
import { execFileSync, spawn } from 'node:child_process';
import { mkdtempSync, mkdirSync, readFileSync, rmSync, statSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { createHash } from 'node:crypto';
import test from 'node:test';

const script = fileURLToPath(new URL('../bin/item-feedback.js', import.meta.url));
const engine = fileURLToPath(new URL('../../bin/geoffrey', import.meta.url));
function fixture() {
  const root = mkdtempSync(join(tmpdir(), 'geoffrey-item-feedback-'));
  const memory = join(root, 'private-memory');
  mkdirSync(join(root, '.geoffrey'));
  mkdirSync(join(memory, 'memory'), { recursive: true });
  writeFileSync(join(root, '.geoffrey', 'current-memory'), memory + '\n');
  return { root, memory, file: join(memory, 'memory', 'briefing-reactions.json'), env: { ...process.env, HOME: root } };
}
function request(section = 'Open loops', overrides = {}) {
  const context = { responseID: 'daily:1000', source: 'Your daily briefing', section, item: 'Check the supplier refund.' };
  context.id = createHash('sha256').update([context.responseID, context.source, context.section, context.item].join('\0')).digest('hex');
  return { context, rating: 'good', more: false, note: '', clear: false, ...overrides };
}
const encoded = value => Buffer.from(JSON.stringify(value)).toString('base64');
function call(f, args) {
  return JSON.parse(execFileSync(process.execPath, [script, ...args], { env: f.env, encoding: 'utf8' }));
}
function save(f, value) { return call(f, ['--payload', encoded(value)]); }

test('all update types save exact item/section context privately through the app command', () => {
  const f = fixture();
  try {
    writeFileSync(join(f.memory, 'memory', 'briefing-feedback.md'), 'Existing owner preferences.\n');
    for (const section of ['Top priorities', 'Schedule', 'Follow-ups', 'Open loops', 'Waiting on', 'Focus blocks', 'Inbox results']) {
      const value = request(section);
      const result = JSON.parse(execFileSync(engine, ['app-item-feedback', '--payload', encoded(value)], { env: f.env, encoding: 'utf8' }));
      assert.equal(result.ok, true);
      assert.deepEqual(result.record.context, value.context);
      assert.equal(call(f, ['--id', value.context.id]).record.rating, 'good');
    }
    assert.equal(JSON.parse(readFileSync(f.file)).records.length, 7);
    assert.equal(statSync(f.file).mode & 0o777, 0o600);
    assert.equal(readFileSync(join(f.memory, 'memory', 'briefing-feedback.md'), 'utf8'), 'Existing owner preferences.\n');
  } finally { rmSync(f.root, { recursive: true, force: true }); }
});

test('good/bad, more coverage, and optional notes remain distinct and retries replace the same record', () => {
  const f = fixture();
  try {
    const value = request();
    save(f, value);
    const updated = { ...value, rating: 'bad', more: true, note: 'This is useful to track, but the details are wrong.' };
    save(f, updated); save(f, updated);
    const records = JSON.parse(readFileSync(f.file)).records;
    assert.equal(records.length, 1);
    assert.equal(records[0].rating, 'bad');
    assert.equal(records[0].more, true);
    save(f, { ...value, rating: null, note: 'Already handled yesterday.' });
    const note = call(f, ['--id', value.context.id]).record;
    assert.equal(note.rating, null);
    assert.equal(note.more, false);
    assert.equal(note.note, 'Already handled yesterday.');
    assert.equal(save(f, { ...value, clear: true }).record, null);
    assert.equal(call(f, ['--id', value.context.id]).record, null);
    assert.equal(JSON.parse(readFileSync(f.file)).records.length, 0);
  } finally { rmSync(f.root, { recursive: true, force: true }); }
});

test('saved reactions reach future prepared context and general chat without becoming action authority', () => {
  const f = fixture();
  try {
    save(f, request('Follow-ups', { more: true, note: 'Keep surfacing supplier replies.' }));
    const context = execFileSync(engine, ['app-context', '--task', 'capability-review'], { env: f.env, encoding: 'utf8' });
    assert.match(context, /Keep surfacing supplier replies/);
    assert.match(context, /More like this means similar information deserves more coverage/);
    assert.match(context, /not task completion or permission/);
    const prompt = execFileSync(engine, ['app-prompt', '--task', 'ask', '--request', 'Plan my day'], { env: f.env, encoding: 'utf8' });
    assert.match(prompt, /briefing-reactions\.json/);
    assert.match(prompt, /Keep urgent obligations and verified risks visible/);
  } finally { rmSync(f.root, { recursive: true, force: true }); }
});

test('invalid requests and damaged stores fail without reporting a save or overwriting feedback', () => {
  const f = fixture();
  try {
    save(f, request());
    const before = readFileSync(f.file, 'utf8');
    for (const value of [request('Open loops', { rating: 'higher' }), request('Open loops', { note: 'a'.repeat(2001) }), request('Open loops', { rating: null })]) {
      assert.throws(() => save(f, value));
      assert.equal(readFileSync(f.file, 'utf8'), before);
    }
    writeFileSync(f.file, '{damaged');
    assert.throws(() => save(f, request()));
    assert.equal(readFileSync(f.file, 'utf8'), '{damaged');
  } finally { rmSync(f.root, { recursive: true, force: true }); }
});

test('a crashed writer does not leave feedback permanently locked', () => {
  const f = fixture();
  try {
    writeFileSync(f.file + '.lock', JSON.stringify({ pid: 2147483647 }));
    assert.equal(save(f, request()).ok, true);
    assert.equal(JSON.parse(readFileSync(f.file)).records.length, 1);
  } finally { rmSync(f.root, { recursive: true, force: true }); }
});

test('concurrent feedback saves preserve every item', async () => {
  const f = fixture();
  try {
    await Promise.all(Array.from({ length: 12 }, (_, i) => new Promise((resolve, reject) => {
      const child = spawn(process.execPath, [script, '--payload', encoded(request(`Section ${i}`))], { env: f.env, stdio: 'ignore' });
      child.on('error', reject);
      child.on('exit', code => code === 0 ? resolve() : reject(new Error(`Save failed: ${code}`)));
    })));
    const records = JSON.parse(readFileSync(f.file)).records;
    assert.equal(records.length, 12);
    assert.equal(new Set(records.map(record => record.context.section)).size, 12);
  } finally { rmSync(f.root, { recursive: true, force: true }); }
});
