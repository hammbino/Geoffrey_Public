#!/usr/bin/env node
// Explicit, retryable backup setup for the already-selected local memory.
import { spawnSync } from 'node:child_process';
import { readFileSync, existsSync } from 'node:fs';
import { homedir } from 'node:os';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';

function run(command, args) {
  return spawnSync(command, args, { encoding: 'utf8', timeout: 45000, stdio: ['ignore', 'pipe', 'pipe'] });
}
function fail(message) {
  console.log(JSON.stringify({ schema_version: 1, state: 'local_only', checked_at: new Date().toISOString(),
    branch: null, head: null, ahead: 0, behind: 0, dirty: false, message,
    recovery: 'Your local memory is safe. Check GitHub sign-in, then choose Set up GitHub backup again.' }));
  process.exitCode = 1;
}
try {
  const root = readFileSync(join(homedir(), '.geoffrey/current-memory'), 'utf8').trim();
  if (!existsSync(join(root, 'memory')) || run('git', ['-C', root, 'rev-parse', '--git-dir']).status !== 0) {
    throw new Error('Create local memory before setting up backup.');
  }
  if (run('git', ['-C', root, 'remote', 'get-url', 'origin']).status !== 0) {
    const identity = run('gh', ['api', 'user', '--jq', '.login']);
    const owner = identity.stdout?.trim();
    if (identity.status !== 0 || !/^[a-zA-Z0-9-]+$/.test(owner ?? '')) throw new Error('Sign in to GitHub before setting up backup.');
    const configured = run('git', ['-C', root, 'config', '--get', 'geoffrey.backupRepository']).stdout?.trim();
    const name = configured || 'geoffrey-memory';
    if (!/^[a-zA-Z0-9][a-zA-Z0-9._-]*$/.test(name)) throw new Error('The saved backup repository name needs review.');
    const repository = `${owner}/${name}`;
    // Creation can succeed remotely even if the response is lost. On retry only
    // an empty, private repository may be adopted; never attach unrelated history.
    run('gh', ['repo', 'create', repository, '--private']);
    const inspected = run('gh', ['repo', 'view', repository, '--json', 'isPrivate,defaultBranchRef,url']);
    let remote;
    try { remote = JSON.parse(inspected.stdout); } catch { /* reported below */ }
    const namedDefaultBranch = typeof remote?.defaultBranchRef?.name === 'string'
      && remote.defaultBranchRef.name.trim().length > 0;
    if (inspected.status !== 0 || remote?.isPrivate !== true || namedDefaultBranch
        || remote.url !== `https://github.com/${repository}`) {
      throw new Error('Could not create an empty private backup. An existing repository with files will not be overwritten.');
    }
    // GitHub may return { name: "" } for an empty repository. Verify Git's
    // actual refs as well, so a misleading API response cannot adopt history.
    const refs = run('git', ['ls-remote', remote.url + '.git']);
    if (refs.status !== 0 || refs.stdout?.trim()) {
      throw new Error('Could not create an empty private backup. An existing repository with files will not be overwritten.');
    }
    if (run('git', ['-C', root, 'remote', 'add', 'origin', remote.url + '.git']).status !== 0) {
      throw new Error('The private backup was created, but could not be linked. Retry setup to finish.');
    }
  }
  const origin = run('git', ['-C', root, 'config', '--get', 'remote.origin.url']).stdout?.trim();
  const githubRemote = /^(?:https:\/\/github\.com\/|git@github\.com:)([a-zA-Z0-9-]+\/[a-zA-Z0-9._-]+?)(?:\.git)?$/.exec(origin ?? '');
  if (!githubRemote) throw new Error('The selected backup is not a verified GitHub repository. Review it before backing up.');
  const existing = run('gh', ['repo', 'view', githubRemote[1], '--json', 'isPrivate']);
  if (existing.status !== 0 || JSON.parse(existing.stdout).isPrivate !== true) {
    throw new Error('The backup must be a private GitHub repository. No memory was pushed.');
  }
  // Reuse the production credential scan, conflict handling, and push proof.
  const result = spawnSync(process.execPath, [fileURLToPath(new URL('./memory-sync.js', import.meta.url)), '--phase', 'backup setup'],
    { stdio: 'inherit', timeout: 120000 });
  process.exitCode = result.status ?? 1;
} catch (error) {
  fail(error.message);
}
