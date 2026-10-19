import test from 'node:test';
import assert from 'node:assert/strict';
import { spawnSync, execFileSync } from 'node:child_process';
import { mkdtempSync, mkdirSync, writeFileSync, readFileSync, rmSync, existsSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';

const script = fileURLToPath(new URL('../../bin/geoffrey', import.meta.url));
function fixture() {
  const home = mkdtempSync(join(tmpdir(), 'geoffrey-backup-journey-'));
  const bin = join(home, 'bin'); mkdirSync(bin);
  writeFileSync(join(bin, 'gh'), `#!/bin/sh
if [ "$1" = api ]; then echo fixture; exit 0; fi
if [ -f "$HOME/fail-backup" ]; then exit 1; fi
if [ "$2" = create ]; then
  git init --bare "$HOME/remote.git" >/dev/null 2>&1
  exit 0
fi
if [ "$2" = view ]; then
  if [ -f "$HOME/occupied" ]; then
    echo '{"isPrivate":true,"defaultBranchRef":{"name":"main"},"url":"https://github.com/fixture/geoffrey-fixture-owner"}'
  elif [ -f "$HOME/blank-default-branch" ]; then
    echo '{"isPrivate":true,"defaultBranchRef":{"name":""},"url":"https://github.com/fixture/geoffrey-fixture-owner"}'
  else
    echo '{"isPrivate":true,"defaultBranchRef":null,"url":"https://github.com/fixture/geoffrey-fixture-owner"}'
  fi
  exit 0
fi
exit 1
`, { mode: 0o700 });
  const config = join(home, 'gitconfig');
  writeFileSync(config, `[url "${home}/remote.git"]\n  insteadOf = https://github.com/fixture/geoffrey-fixture-owner.git\n`);
  const env = { ...process.env, HOME: home, PATH: `${bin}:${process.env.PATH}`, GIT_CONFIG_GLOBAL: config, GIT_CONFIG_NOSYSTEM: '1' };
  const run = (...args) => spawnSync(script, args, { env, encoding: 'utf8', input: '', timeout: 20000 });
  const created = run('memory', '--name', 'Fixture Owner', '--business', 'Personal', '--local');
  assert.equal(created.status, 0, created.stderr);
  return { home, run, env, memory: join(home, 'Geoffrey') };
}

test('first-use local memory requires no GitHub login, records selection, and reports optional backup', () => {
  const f = fixture();
  try {
    assert.equal(readFileSync(join(f.home, '.geoffrey/current-memory'), 'utf8').trim(), f.memory);
    assert.equal(existsSync(join(f.home, 'remote.git')), false);
    const status = f.run('app-sync-status');
    assert.equal(JSON.parse(status.stdout).state, 'local_only');
    const repeated = f.run('memory', '--name', 'Fixture Owner', '--business', 'Personal', '--local');
    assert.equal(repeated.status, 1, 'existing memory is never overwritten');
  } finally { rmSync(f.home, { recursive: true, force: true }); }
});

test('failed backup setup retries to a real push and subsequent retries are idempotent', () => {
  const f = fixture();
  try {
    const before = execFileSync('git', ['-C', f.memory, 'rev-parse', 'HEAD'], { encoding: 'utf8' }).trim();
    writeFileSync(join(f.home, 'fail-backup'), '');
    const failed = f.run('app-backup');
    assert.equal(failed.status, 1, failed.stderr);
    assert.equal(JSON.parse(failed.stdout).state, 'local_only');
    assert.equal(readFileSync(join(f.home, '.geoffrey/current-memory'), 'utf8').trim(), f.memory);
    rmSync(join(f.home, 'fail-backup'));
    for (let attempt = 0; attempt < 2; attempt++) {
      const retry = f.run('app-backup');
      assert.equal(retry.status, 0, retry.stderr || retry.stdout);
      assert.equal(JSON.parse(retry.stdout).state, 'synced');
      assert.equal(execFileSync('git', ['--git-dir', join(f.home, 'remote.git'), 'rev-parse', 'refs/heads/main'], { encoding: 'utf8' }).trim(), before);
    }
  } finally { rmSync(f.home, { recursive: true, force: true }); }
});

test('backup setup never adopts an existing repository with unrelated history', () => {
  const f = fixture();
  try {
    writeFileSync(join(f.home, 'occupied'), '');
    const result = f.run('app-backup');
    assert.equal(result.status, 1);
    assert.match(JSON.parse(result.stdout).message, /will not be overwritten/);
    assert.equal(spawnSync('git', ['-C', f.memory, 'remote', 'get-url', 'origin']).status, 2);
  } finally { rmSync(f.home, { recursive: true, force: true }); }
});

test('backup setup accepts GitHub’s blank default branch only when Git has no refs', () => {
  const f = fixture();
  try {
    writeFileSync(join(f.home, 'blank-default-branch'), '');
    const retry = f.run('app-backup');
    assert.equal(retry.status, 0, retry.stderr || retry.stdout);
    assert.equal(JSON.parse(retry.stdout).state, 'synced');
    assert.equal(execFileSync('git', ['-C', f.memory, 'remote', 'get-url', 'origin'], { encoding: 'utf8' }).trim(),
      'https://github.com/fixture/geoffrey-fixture-owner.git');
  } finally { rmSync(f.home, { recursive: true, force: true }); }
});

test('backup setup refuses existing Git refs even when GitHub reports a blank default branch', () => {
  const f = fixture();
  try {
    writeFileSync(join(f.home, 'blank-default-branch'), '');
    execFileSync('git', ['init', '--bare', join(f.home, 'remote.git')]);
    execFileSync('git', ['--git-dir', join(f.home, 'remote.git'), 'fetch', f.memory, 'main:refs/heads/main']);
    const result = f.run('app-backup');
    assert.equal(result.status, 1);
    assert.match(JSON.parse(result.stdout).message, /will not be overwritten/);
    assert.equal(spawnSync('git', ['-C', f.memory, 'remote', 'get-url', 'origin']).status, 2);
  } finally { rmSync(f.home, { recursive: true, force: true }); }
});

test('names containing punctuation are preserved literally in local memory', () => {
  const home = mkdtempSync(join(tmpdir(), 'geoffrey-memory-names-'));
  try {
    const name = 'A & B / USER_NAME';
    const business = 'Sales/Service & Support';
    const result = spawnSync(script, ['memory', '--name', name, '--business', business, '--local'], {
      env: { ...process.env, HOME: home, GIT_CONFIG_GLOBAL: '/dev/null', GIT_CONFIG_NOSYSTEM: '1' },
      encoding: 'utf8', input: '', timeout: 10000,
    });
    assert.equal(result.status, 0, result.stderr);
    const user = readFileSync(join(home, 'Geoffrey/memory/user.md'), 'utf8');
    assert.ok(user.includes(name));
    assert.ok(user.includes(business));
  } finally { rmSync(home, { recursive: true, force: true }); }
});

test('a shell entry point without its required runtime is not reported ready', () => {
  const home = mkdtempSync(join(tmpdir(), 'geoffrey-missing-runtime-'));
  try {
    const result = spawnSync(script, ['app-status'], {
      env: { ...process.env, HOME: home, PATH: '/usr/bin:/bin:/usr/sbin:/sbin' }, encoding: 'utf8', timeout: 10000,
    });
    assert.equal(result.status, 0, result.stderr);
    assert.match(result.stdout, /^app\tneeds_install$/m);
  } finally { rmSync(home, { recursive: true, force: true }); }
});
