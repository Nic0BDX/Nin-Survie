import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { mkdirSync, mkdtempSync, realpathSync, renameSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { basename, dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import test from 'node:test';

const runner = fileURLToPath(new URL('./github-sync.mjs', import.meta.url));
const branch = 'studio/review';
const invoke = (bin, args, cwd) => spawnSync(bin, args, { cwd, encoding: 'utf8', windowsHide: true, timeout: 30000 });

function git(cwd, ...args) {
  const result = invoke('git', args, cwd);
  assert.equal(result.status, 0, String(result.stderr || result.error));
  return result.stdout.trim();
}

function sandbox(t) {
  const base = realpathSync(tmpdir());
  const root = mkdtempSync(join(base, 'keravel-github-sync-'));
  t.after(() => {
    const actual = realpathSync(root);
    assert.equal(resolve(dirname(actual)), resolve(base));
    assert.ok(basename(actual).startsWith('keravel-github-sync-'));
    rmSync(actual, { recursive: true, force: true, maxRetries: 2 });
  });
  const work = join(root, 'checkout');
  const remote = join(root, 'remote.git');
  mkdirSync(work);
  git(root, 'init', '--bare', remote);
  git(work, 'init', '-b', branch);
  git(work, 'config', 'user.name', 'Fixture Keravel');
  git(work, 'config', 'user.email', 'fixture@local.invalid');
  git(work, 'remote', 'add', 'origin', remote);
  return { root, work, remote };
}

function commit(work, name) {
  writeFileSync(join(work, name + '.txt'), name + '\n');
  git(work, 'add', '--', name + '.txt');
  git(work, 'commit', '-m', name);
  return git(work, 'rev-parse', 'HEAD');
}

function runnerCall(work, command, ...extra) {
  return invoke(process.execPath, [runner, command, '--repo', work, '--branch', branch, ...extra], work);
}

function status(work) {
  const result = runnerCall(work, 'status');
  assert.equal(result.status, 0, String(result.stderr));
  return JSON.parse(result.stdout);
}

test('approbation explicite, branche intacte et vérification distante', t => {
  const { work, remote } = sandbox(t);
  const first = commit(work, 'validé');
  const waiting = runnerCall(work, 'run-once');
  assert.equal(waiting.status, 0, waiting.stderr);
  assert.equal(status(work).last.status, 'waiting_approval');
  assert.equal(git(work, 'ls-remote', remote), '');
  assert.equal(runnerCall(work, 'approve', '--commit', first).status, 0);
  const draft = commit(work, 'brouillon');
  assert.equal(runnerCall(work, 'run-once').status, 0);
  assert.equal(status(work).last.status, 'pushed_verified');
  assert.equal(git(remote, 'rev-parse', 'refs/heads/' + branch), first);
  assert.equal(git(work, 'rev-parse', 'HEAD'), draft);
  assert.equal(runnerCall(work, 'approve', '--commit', first).status, 1);
  assert.equal(runnerCall(work, 'approve', '--commit', draft).status, 0);
  assert.equal(runnerCall(work, 'run-once').status, 0);
  assert.equal(git(remote, 'rev-parse', 'refs/heads/' + branch), draft);
  assert.equal(runnerCall(work, 'run-once').status, 0);
  assert.equal(status(work).last.status, 'verified');
});

test('le distant inaccessible conserve le commit, une divergence reste intacte', t => {
  const { root, work, remote } = sandbox(t);
  const base = commit(work, 'base');
  git(work, 'push', 'origin', 'HEAD:refs/heads/' + branch);
  const approved = commit(work, 'approved');
  assert.equal(runnerCall(work, 'approve', '--commit', approved).status, 0);
  const offline = join(root, 'remote-offline.git');
  renameSync(remote, offline);
  try {
    const disconnected = runnerCall(work, 'run-once', '--retries', '1');
    assert.equal(disconnected.status, 2, disconnected.stderr);
    assert.equal(status(work).last.status, 'pending');
    assert.equal(status(work).last.attempt, 2);
    assert.equal(status(work).approval.commit, approved);
  } finally { renameSync(offline, remote); }
  const other = join(root, 'second-checkout');
  git(root, 'clone', '-b', branch, remote, other);
  git(other, 'config', 'user.name', 'Autre fixture Keravel');
  git(other, 'config', 'user.email', 'fixture@local.invalid');
  assert.equal(git(other, 'rev-parse', 'HEAD'), base);
  const divergent = commit(other, 'divergent');
  git(other, 'push', 'origin', 'HEAD:refs/heads/' + branch);
  const blocked = runnerCall(work, 'run-once');
  assert.equal(blocked.status, 2, blocked.stderr);
  assert.equal(status(work).last.status, 'blocked_divergence');
  assert.equal(git(remote, 'rev-parse', 'refs/heads/' + branch), divergent);
});

test('cadence répétée et limitée, noms de production interdits', t => {
  const { work } = sandbox(t);
  const first = commit(work, 'premier');
  const badBranch = invoke(process.execPath, [runner, 'approve', '--repo', work, '--branch', 'main', '--commit', first], work);
  assert.equal(badBranch.status, 1);
  assert.equal(runnerCall(work, 'approve', '--commit', first).status, 0);
  const result = runnerCall(work, 'start', '--interval-minutes', '0.015', '--cycle-minutes', '0.043');
  assert.equal(result.status, 0, result.stderr);
  assert.match(result.stdout, /pushed_verified/);
  assert.match(result.stdout, /\nverified/);
  assert.equal(status(work).runner, null);
});
