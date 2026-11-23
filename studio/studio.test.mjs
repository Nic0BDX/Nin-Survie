import { spawn, spawnSync } from 'node:child_process';
import { copyFileSync, existsSync, mkdirSync, mkdtempSync, readFileSync, realpathSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { test } from 'node:test';
import assert from 'node:assert/strict';

const launcher = fileURLToPath(new URL('studio.mjs', import.meta.url));
const budget = fileURLToPath(new URL('token-budget.mjs', import.meta.url));

const mock = `
import { readFileSync, writeFileSync } from 'node:fs';
if (process.argv.includes('--version')) {
  console.log('Fixture CLI');
} else if (process.argv.includes('login')) {
  console.log('Fixture authentication');
} else {
  let prompt = '';
  for await (const input of process.stdin) prompt += input;
  const match = prompt.match(/Fichiers autorisés : ([^.]+\\.txt)/);
  const path = match[1];
  if (prompt.includes('attendre')) await new Promise(resolve => setTimeout(resolve, 1500));
  if (prompt.includes('bloquer la fixture')) await new Promise(resolve => setTimeout(resolve, 4000));
  if (path === 'two.txt' && readFileSync('one.txt', 'utf8') !== 'fixture one.txt\\n') process.exit(4);
  writeFileSync(path, 'fixture ' + path + '\\n');
  if (prompt.includes('dépasser le lot')) writeFileSync('outside.txt', 'unsafe fixture');
  console.log(JSON.stringify({ type: 'turn.completed', usage: { input_tokens: 24, output_tokens: 11, cached_input_tokens: 8 } }));
}
`;

function fixture(t, tasks) {
  const base = realpathSync(tmpdir());
  const project = mkdtempSync(join(base, 'keravel-studio-test-'));
  t.after(() => {
    const verified = realpathSync(project);
    assert.equal(verified, project);
    assert.ok(verified.startsWith(join(base, 'keravel-studio-test-')));
    rmSync(verified, { recursive: true, force: true });
  });
  const studio = join(project, 'studio');
  mkdirSync(studio);
  copyFileSync(launcher, join(studio, 'studio.mjs'));
  copyFileSync(budget, join(studio, 'token-budget.mjs'));
  writeFileSync(join(studio, 'tasks.json'), JSON.stringify(tasks));
  writeFileSync(join(studio, 'fixture.mjs'), mock);
  writeFileSync(join(project, 'one.txt'), 'original\n');
  writeFileSync(join(project, 'two.txt'), 'original\n');
  return {
    project,
    statePath: join(project, '.studio', 'state.json'),
    readState: () => JSON.parse(readFileSync(join(project, '.studio', 'state.json'), 'utf8')),
    invoke: (...args) => spawnSync(process.execPath, [join(studio, 'studio.mjs'), ...args],
      { cwd: project, encoding: 'utf8', timeout: 25_000, windowsHide: true }),
    launch: (...args) => spawn(process.execPath, [join(studio, 'studio.mjs'), ...args],
      { cwd: project, windowsHide: true, stdio: 'ignore' }),
    cli: join(studio, 'fixture.mjs'),
  };
}

function job(id, priority, file, instructions, dependsOn = []) {
  return { id, priority, files: [file], title: 'Fixture ' + id, instructions, dependsOn,
    checks: [{ command: process.execPath, args: ['-e', 'process.exit(0)'] }] };
}

test('validates isolated patches and runs a dependency against the private integration', t => {
  const f = fixture(t, [
    job('second', 'P1', 'two.txt', 'Créer la suite.', ['first']),
    job('first', 'P0', 'one.txt', 'Préparer la base.'),
  ]);
  const response = f.invoke('start', '--codex', f.cli, '--workers', '2', '--attempts', '1');
  assert.equal(response.status, 0, response.stderr + response.stdout + JSON.stringify(f.readState()));
  const state = f.readState();
  assert.equal(state.status, 'complete');
  for (const task of Object.values(state.tasks)) {
    assert.equal(task.status, 'validated', task.reason);
    const run = task.attempts[0];
    assert.ok(run.spawned && run.commit && run.patch);
    assert.equal(run.usage[0].input_tokens, 24);
    assert.ok(run.checks[0].ok);
  }
  assert.equal(readFileSync(join(f.project, 'one.txt'), 'utf8'), 'original\n');
  assert.equal(readFileSync(join(f.project, 'two.txt'), 'utf8'), 'original\n');
  assert.match(readFileSync(join(f.project, 'NIGHTLY_REPORT.md'), 'utf8'), /Agents démarrés : 2/);
});

test('retains an invalid lot without publishing a patch or changing the source', t => {
  const f = fixture(t, [job('violation', 'P1', 'one.txt', 'Cette fixture va dépasser le lot.')]);
  const response = f.invoke('start', '--codex', f.cli, '--attempts', '1');
  assert.equal(response.status, 1);
  const task = f.readState().tasks.violation;
  assert.equal(task.status, 'blocked');
  assert.match(task.reason, /Fichiers hors lot : outside.txt/);
  assert.equal(task.attempts[0].patch, undefined);
  assert.equal(readFileSync(join(f.project, 'one.txt'), 'utf8'), 'original\n');
});

test('pauses after the active lot and recovers a dead worker from its checkpoint', async t => {
  const f = fixture(t, [
    job('first', 'P0', 'one.txt', 'Faire attendre la fixture.'),
    job('second', 'P1', 'two.txt', 'Créer la suite.', ['first']),
  ]);
  const child = f.launch('start', '--codex', f.cli, '--workers', '1');
  const exited = new Promise(resolveExit => child.once('exit', resolveExit));
  let state;
  for (let retry = 0; retry < 50; retry++) {
    try {
      state = f.readState();
      if (state.tasks.first.attempts[0]?.spawned) break;
    } catch (error) {
      if (error.code !== 'ENOENT') throw error;
    }
    await new Promise(resolveTick => setTimeout(resolveTick, 130));
  }
  assert.ok(state?.tasks.first.attempts[0]?.spawned);
  const pause = f.invoke('pause');
  assert.equal(pause.status, 0, pause.stderr);
  assert.equal(await exited, 0);
  state = f.readState();
  assert.equal(state.status, 'paused');
  assert.equal(state.tasks.first.status, 'validated');
  assert.equal(state.tasks.second.status, 'pending');
  state.status = 'running';
  state.tasks.second.status = 'running';
  state.tasks.second.attempts.push({ pid: 0, outcome: 'running', usage: [] });
  writeFileSync(f.statePath, JSON.stringify(state));
  const recovered = f.invoke('recover');
  assert.equal(recovered.status, 0, recovered.stderr);
  assert.equal(f.readState().tasks.second.attempts[0].outcome, 'interrupted');
  const resume = f.invoke('resume');
  assert.equal(resume.status, 0, resume.stderr + resume.stdout);
  assert.equal(f.readState().tasks.second.status, 'validated');
  assert.equal(f.readState().tasks.first.attempts.length, 1);
});

test('detached launcher reports its PID and stop checkpoints its owned worker', async t => {
  const f = fixture(t, [job('interruption', 'P0', 'one.txt', 'Il faut bloquer la fixture.')]);
  const launch = f.invoke('start', '--background', '--codex', f.cli);
  assert.equal(launch.status, 0, launch.stderr + launch.stdout);
  assert.match(launch.stdout, /Lanceur PID \d+ démarré/);
  let state;
  for (let retry = 0; retry < 50; retry++) {
    try {
      state = f.readState();
      if (state.tasks.interruption.attempts[0]?.spawned) break;
    } catch (error) {
      if (error.code !== 'ENOENT') throw error;
    }
    await new Promise(resolveTick => setTimeout(resolveTick, 130));
  }
  assert.ok(state?.tasks.interruption.attempts[0]?.spawned);
  const result = f.invoke('stop');
  assert.equal(result.status, 0, result.stderr);
  for (let retry = 0; retry < 60; retry++) {
    state = f.readState();
    if (state.status === 'stopped' && !existsSync(join(f.project, '.studio', 'manager.lock'))) break;
    await new Promise(resolveTick => setTimeout(resolveTick, 150));
  }
  assert.equal(state.status, 'stopped');
  assert.equal(state.tasks.interruption.attempts[0].outcome, 'interrupted');
  assert.equal(readFileSync(join(f.project, 'one.txt'), 'utf8'), 'original\n');
});
