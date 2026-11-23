import { spawn } from 'node:child_process';
import { createHash, randomUUID } from 'node:crypto';
import { appendFileSync, closeSync, existsSync, mkdirSync, openSync, readFileSync, renameSync, unlinkSync, writeFileSync } from 'node:fs';
import { dirname, isAbsolute, join, resolve } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { setTimeout as wait } from 'node:timers/promises';

const defaultRepo = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const iso = () => new Date().toISOString();
const oid = /^(?:[0-9a-f]{40}|[0-9a-f]{64})$/;
const actions = new Set(['approve', 'start', 'run-once', 'status', 'stop', 'recover', 'help']);
const windows = process.platform === 'win32';

function parse(argv) {
  const [action = 'status', ...args] = argv;
  if (!actions.has(action)) throw Error('Commande inconnue.');
  const flags = {};
  for (let i = 0; i < args.length; i += 2) {
    const key = args[i];
    const value = args[i + 1];
    if (!['--repo', '--branch', '--remote', '--commit', '--interval-minutes', '--cycle-minutes', '--retries'].includes(key)
      || !value || value.startsWith('--') || Object.hasOwn(flags, key)) throw Error('Option invalide : ' + key);
    flags[key] = value;
  }
  const branch = flags['--branch'] ?? 'studio/review';
  const remote = flags['--remote'] ?? 'origin';
  if (!/^(?:studio|review)\/[a-z0-9][a-z0-9._/-]{0,99}$/i.test(branch)) throw Error('Choisir une branche dédiée studio/* ou review/*.');
  if (!/^[a-z0-9][a-z0-9._-]{0,62}$/i.test(remote)) throw Error('Nom du distant invalide.');
  const number = (key, fallback, low, high) => {
    const n = Number(flags[key] ?? fallback);
    if (!Number.isFinite(n) || n < low || n > high) throw Error(key + ' : valeur hors limites.');
    return n;
  };
  const retries = number('--retries', 2, 0, 5);
  if (!Number.isInteger(retries)) throw Error('--retries doit être entier.');
  if ((action === 'approve') !== Object.hasOwn(flags, '--commit')
    || (action === 'approve' && !oid.test(flags['--commit']))) throw Error('approve exige --commit et son identifiant Git complet.');
  return { action, branch, remote, commit: flags['--commit'], repo: resolve(flags['--repo'] ?? defaultRepo),
    interval: Math.round(number('--interval-minutes', 10, 0.01, 120) * 60000),
    duration: Math.round(number('--cycle-minutes', 360, 0.01, 1440) * 60000), retries };
}

function read(path) {
  return existsSync(path) ? JSON.parse(readFileSync(path, 'utf8')) : null;
}

function write(path, value) {
  const temp = path + '.' + randomUUID() + '.tmp';
  writeFileSync(temp, JSON.stringify(value, null, 2) + '\n', { flag: 'wx' });
  renameSync(temp, path);
}

async function git(repo, args, timeout = 20000) {
  return new Promise(resolve => {
    const proc = spawn('git', ['-c', 'push.followTags=false', ...args], {
      cwd: repo, windowsHide: true, stdio: ['ignore', 'pipe', 'pipe'],
      detached: !windows,
      env: { ...process.env, GIT_TERMINAL_PROMPT: '0', GCM_INTERACTIVE: 'Never' },
    });
    let out = '';
    let err = '';
    let expired = false;
    let spawnFailed = false;
    proc.stdout.setEncoding('utf8').on('data', chunk => { if (out.length < 131072) out += chunk; });
    proc.stderr.setEncoding('utf8').on('data', chunk => { if (err.length < 32768) err += chunk; });
    proc.on('error', () => { spawnFailed = true; });
    const timer = setTimeout(() => {
      expired = true;
      if (!proc.pid) return;
      if (proc.exitCode !== null || proc.signalCode !== null) {
        proc.stdout.destroy();
        proc.stderr.destroy();
        return;
      }
      if (windows) {
        const killer = spawn('taskkill.exe', ['/PID', String(proc.pid), '/T', '/F'], { windowsHide: true, stdio: 'ignore' });
        killer.once('error', () => proc.kill('SIGKILL'));
        killer.once('close', status => { if (status !== 0) proc.kill('SIGKILL'); });
      } else {
        try { process.kill(-proc.pid, 'SIGKILL'); }
        catch { proc.kill('SIGKILL'); }
      }
    }, timeout);
    proc.once('close', code => {
      clearTimeout(timer);
      const problem = expired ? 'timeout' : spawnFailed ? 'git_unavailable'
        : /non-fast-forward|fetch first|\[rejected\]|remote rejected/i.test(err) ? 'rejected'
        : /authenticat|permission denied|could not read username|access denied/i.test(err) ? 'auth'
        : /could not connect|failed to connect|could not resolve|unable to access|not appear to be a git repository|could not read from remote/i.test(err) ? 'connection'
        : 'git_error';
      resolve({ ok: code === 0 && !expired && !spawnFailed, code, out: out.trim(), problem });
    });
  });
}

async function requireGit(repo, args, message) {
  const result = await git(repo, args);
  if (!result.ok) throw Error(message + ' (' + result.problem + ').');
  return result.out;
}

function remoteAddress(value, repo) {
  if (!value || /[\r\n\0]/.test(value)) throw Error('Adresse distante unique requise.');
  if (isAbsolute(value) || /^\.{1,2}[\\/]/.test(value)) return pathToFileURL(resolve(repo, value)).href;
  if (/^(?:[a-z0-9._-]+@)?[a-z0-9.-]+:[a-z0-9_./~-]+$/i.test(value)) return value;
  if (!/^(?:https|ssh|file):\/\//i.test(value)) throw Error('Le distant doit utiliser HTTPS, SSH ou un dépôt local.');
  const url = new URL(value);
  if (url.password || (url.protocol === 'https:' && url.username) || url.search || url.hash) {
    throw Error('Utiliser le gestionnaire d’identifiants Git plutôt que des identifiants dans l’adresse.');
  }
  return url.href;
}

async function repository(config) {
  const repo = await requireGit(config.repo, ['rev-parse', '--show-toplevel'], 'Un clone Git de travail est nécessaire');
  const common = await requireGit(repo, ['rev-parse', '--path-format=absolute', '--git-common-dir'], 'Métadonnées Git inaccessibles');
  await requireGit(repo, ['check-ref-format', 'refs/heads/' + config.branch], 'Branche invalide');
  const key = createHash('sha256').update(config.remote + '\0' + config.branch).digest('hex').slice(0, 18);
  const root = join(common, 'keravel-sync', key);
  mkdirSync(root, { recursive: true });
  return { ...config, repo, root, ref: 'refs/heads/' + config.branch,
    approval: join(root, 'approval.json'), state: join(root, 'state.json'), lock: join(root, 'runner.lock'),
    cycleLock: join(root, 'cycle.lock'), stop: join(root, 'stop.json'), log: join(root, 'events.jsonl') };
}

async function destination(config) {
  const readUrl = await requireGit(config.repo, ['remote', 'get-url', '--all', config.remote], 'Distant de lecture introuvable');
  const pushUrl = await requireGit(config.repo, ['remote', 'get-url', '--push', '--all', config.remote], 'Distant d’écriture introuvable');
  const address = remoteAddress(readUrl, config.repo);
  if (address !== remoteAddress(pushUrl, config.repo)) throw Error('Lecture et écriture doivent désigner le même dépôt.');
  return { address, digest: createHash('sha256').update(address).digest('hex') };
}

function event(config, status, details = {}) {
  const next = { at: iso(), status, ...details };
  appendFileSync(config.log, JSON.stringify(next) + '\n');
  return next;
}

function reachable(pid) {
  if (!Number.isSafeInteger(pid) || pid <= 0) return false;
  try { process.kill(pid, 0); return true; }
  catch (error) { return error.code === 'EPERM'; }
}

function lock(path) {
  const value = { id: randomUUID(), pid: process.pid, started: iso() };
  let fd;
  try { fd = openSync(path, 'wx'); }
  catch (error) {
    if (error.code === 'EEXIST') throw Error('Verrou GitHub sync occupé. Consulter status ou recover.');
    throw error;
  }
  try { writeFileSync(fd, JSON.stringify(value) + '\n'); }
  finally { closeSync(fd); }
  return value;
}

function release(path, id) {
  if (read(path)?.id === id) unlinkSync(path);
}

async function approve(config) {
  const access = lock(config.cycleLock);
  try {
    const head = await requireGit(config.repo, ['rev-parse', '--verify', config.ref + '^{commit}'], 'Branche locale introuvable');
    if (head !== config.commit) throw Error('L’identifiant approuvé doit correspondre à la tête de la branche de revue locale.');
    const { digest } = await destination(config);
    const approval = { branch: config.branch, remote: config.remote, destination_sha256: digest, commit: head, approved_at: iso() };
    write(config.approval, approval);
    event(config, 'approved', { commit: head });
    console.log('Commit approuvé : ' + head);
  } finally { release(config.cycleLock, access.id); }
}

async function ancestry(config, old, next, address, timeout) {
  let known = await git(config.repo, ['cat-file', '-e', old + '^{commit}'], timeout);
  if (!known.ok) {
    // Fetch objects only. Keep the source branch, index and tracking refs untouched.
    const fetched = await git(config.repo, ['fetch', '--no-tags', '--no-write-fetch-head', '--', address, config.ref], timeout);
    if (!fetched.ok) return { error: fetched.problem };
    known = await git(config.repo, ['cat-file', '-e', old + '^{commit}'], timeout);
  }
  if (!known.ok) return { error: 'remote_changed' };
  const result = await git(config.repo, ['merge-base', '--is-ancestor', old, next], timeout);
  return result.ok ? { yes: true } : result.code === 1 ? { yes: false } : { error: result.problem };
}

async function remoteHead(config, address, timeout) {
  const result = await git(config.repo, ['ls-remote', '--refs', '--', address, config.ref], timeout);
  if (!result.ok) return { error: result.problem };
  if (!result.out) return { head: null };
  const [head, found] = result.out.split(/\s+/);
  return oid.test(head) && found === config.ref ? { head } : { error: 'invalid_remote_response' };
}

async function sync(config, timeout) {
  const approval = read(config.approval);
  if (!approval) return { status: 'waiting_approval' };
  const commit = approval.commit;
  if (!oid.test(commit)) return { status: 'blocked_local', reason: 'invalid_approval' };
  const { address, digest } = await destination(config);
  if (digest !== approval.destination_sha256) return { status: 'blocked_local', commit, reason: 'destination_changed' };
  const local = await git(config.repo, ['merge-base', '--is-ancestor', commit, config.ref], timeout());
  if (!local.ok) return { status: 'blocked_local', commit, reason: 'approved_commit_not_on_branch' };
  const before = await remoteHead(config, address, timeout());
  if (before.error) return { status: 'pending', commit, reason: before.error };
  if (before.head === commit) return { status: 'verified', commit, remote_oid: before.head };
  if (before.head) {
    const forward = await ancestry(config, before.head, commit, address, timeout());
    if (forward.error) return { status: 'pending', commit, reason: forward.error };
    if (!forward.yes) {
      const included = await ancestry(config, commit, before.head, address, timeout());
      if (included.yes) return { status: 'verified_included', commit, remote_oid: before.head };
      if (included.error) return { status: 'pending', commit, reason: included.error };
      return { status: 'blocked_divergence', commit, remote_oid: before.head };
    }
  }
  if (timeout() <= 1) return { status: 'pending', commit, reason: 'cycle_limit' };
  // An explicit OID and destination ref suppress changes to any other remote ref.
  const pushed = await git(config.repo, ['push', '--porcelain', '--', address, commit + ':' + config.ref], timeout());
  if (!pushed.ok) return { status: 'pending', commit, reason: pushed.problem };
  const after = await remoteHead(config, address, timeout());
  if (after.head !== commit) return { status: 'pending', commit, reason: after.error ?? 'remote_oid_mismatch', remote_oid: after.head ?? null };
  return { status: 'pushed_verified', commit, remote_oid: after.head };
}

async function cycle(config, owner) {
  const deadline = Date.now() + config.duration;
  const timeout = () => Math.max(1, Math.min(20000, deadline - Date.now()));
  const stopRequested = () => read(config.stop)?.id === owner.id;
  const once = config.action === 'run-once';
  let last = null;
  let signal = false;
  const requestStop = () => { signal = true; };
  process.on('SIGINT', requestStop);
  process.on('SIGTERM', requestStop);
  event(config, 'runner_started', { pid: process.pid, deadline: new Date(deadline).toISOString() });
  try {
    while (!signal && !stopRequested() && Date.now() < deadline) {
      const started = Date.now();
      for (let i = 0; i <= config.retries && !signal && !stopRequested() && Date.now() < deadline; i++) {
        let access;
        try {
          access = lock(config.cycleLock);
          last = await sync(config, timeout);
        } catch {
          last = { status: 'blocked_local', reason: access ? 'git_configuration_or_checkpoint' : 'cycle_lock_busy' };
        } finally {
          if (access) release(config.cycleLock, access.id);
        }
        const checkpoint = event(config, last.status, { ...last, attempt: i + 1 });
        write(config.state, checkpoint);
        console.log(checkpoint.status, checkpoint.commit ?? '', checkpoint.reason ?? '');
        if (last.status !== 'pending' || i === config.retries) break;
        await sleepUntil(Math.min(deadline, Date.now() + 1500 * (2 ** i)));
      }
      if (once) break;
      await sleepUntil(Math.min(deadline, started + config.interval));
    }
  } finally {
    process.off('SIGINT', requestStop);
    process.off('SIGTERM', requestStop);
    event(config, 'runner_finished', { result: last?.status ?? 'no_cycle' });
  }
  return last != null && ['waiting_approval', 'verified', 'verified_included', 'pushed_verified'].includes(last.status) ? 0 : 2;

  async function sleepUntil(end) {
    while (!signal && !stopRequested() && Date.now() < end) {
      await wait(Math.min(300, Math.max(1, end - Date.now())));
    }
  }
}

function help() {
  console.log([
    'node studio/github-sync.mjs <approve|start|run-once|status|stop|recover>',
    'Options : --repo <clone> --branch <studio/review> --remote <origin>',
    'Approbation : approve --commit <OID complet de la branche locale de revue>',
    'Cadence : start [--interval-minutes 10] [--cycle-minutes 360] [--retries 2]',
    'Appliquer et contrôler les lots sur une branche de revue issue du dépôt distant.',
    'Les snapshots internes du studio ont un historique distinct. La boucle publie uniquement l’OID approuvé.',
  ].join('\n'));
}

async function main() {
  const config = parse(process.argv.slice(2));
  if (config.action === 'help') return help();
  const repo = await repository(config);
  if (repo.action === 'approve') return approve(repo);
  const current = () => read(repo.lock);
  if (repo.action === 'status') {
    const owner = current();
    console.log(JSON.stringify({ branch: repo.branch, remote: repo.remote, approval: read(repo.approval),
      last: read(repo.state), runner: owner ? { ...owner, pid_responds: reachable(owner.pid) } : null,
      stop_requested: owner != null && read(repo.stop)?.id === owner.id, events_file: repo.log }, null, 2));
    return;
  }
  if (repo.action === 'stop') {
    const owner = current();
    if (owner && reachable(owner.pid)) {
      write(repo.stop, { id: owner.id, at: iso() });
      event(repo, 'stop_requested');
      console.log('Arrêt demandé. L’opération Git courante a un délai maximal de 20 s.');
    } else console.log('Aucun processus de synchronisation joignable.');
    return;
  }
  if (repo.action === 'recover') {
    for (const path of [repo.lock, repo.cycleLock]) {
      const owner = read(path);
      if (!owner) continue;
      if (reachable(owner.pid)) throw Error('Le PID du verrou répond encore.');
      release(path, owner.id);
    }
    event(repo, 'recovered');
    console.log('Verrous orphelins libérés. L’approbation et le dernier résultat sont conservés.');
    return;
  }
  const owner = lock(repo.lock);
  try { process.exitCode = await cycle(repo, owner); }
  finally { release(repo.lock, owner.id); }
}

await main().catch(error => {
  console.error(error.message);
  process.exitCode = 1;
});
