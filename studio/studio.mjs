import { spawn, spawnSync } from 'node:child_process';
import { randomUUID } from 'node:crypto';
import {
  appendFileSync, closeSync, copyFileSync, existsSync, lstatSync, mkdirSync, openSync,
  readFileSync, readdirSync, renameSync, rmSync, statSync, writeFileSync,
} from 'node:fs';
import { dirname, isAbsolute, join, relative, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { budgetDecision, loadPolicy, MODES, readUsage, selectMode } from './token-budget.mjs';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const studio = join(root, '.studio');
const statePath = join(studio, 'state.json');
const lockPath = join(studio, 'manager.lock');
const controlPath = join(studio, 'control.json');
const reportPath = join(root, 'NIGHTLY_REPORT.md');
const acceptedStates = new Set(['start', 'status', 'pause', 'resume', 'stop', 'report', 'recover']);
const windows = process.platform === 'win32';
const priorities = new Set(['P0', 'P1', 'P2', 'P3', 'P4']);
const excluded = new Set(['.git', '.studio', '.godot', '.vercel', '.vscode', 'dist', 'node_modules', 'nightly_report.md']);
const seconds = value => Math.round(value / 1000);
const timestamp = () => new Date().toISOString();
const read = path => existsSync(path) ? JSON.parse(readFileSync(path, 'utf8')) : null;
const safePart = part => /^[a-zA-Z0-9][a-zA-Z0-9_-]{0,63}$/.test(part);

function write(path, value) {
  mkdirSync(dirname(path), { recursive: true });
  const pending = path + '.' + randomUUID() + '.tmp';
  writeFileSync(pending, JSON.stringify(value, null, 2) + '\n');
  renameSync(pending, path);
}

function parse(argv) {
  const [command = 'status', ...args] = argv;
  if (!acceptedStates.has(command)) throw new Error('Commande inconnue : ' + command);
  const values = {};
  const names = new Set(['workers', 'minutes', 'task-minutes', 'attempts', 'codex', 'mode', 'task-tokens', 'agent-tokens', 'cycle-tokens', 'night-tokens', 'snapshot-mb']);
  for (let at = 0; at < args.length; at++) {
    const key = args[at].slice(2);
    if (!args[at].startsWith('--') || Object.hasOwn(values, key)) throw new Error('Option invalide : ' + args[at]);
    if (key === 'night' || key === 'background') {
      values[key] = true;
      continue;
    }
    if (!names.has(key) || !args[at + 1] || args[at + 1].startsWith('--')) throw new Error('Option invalide : ' + args[at]);
    values[key] = args[++at];
  }
  const integer = (key, fallback, max) => {
    if (!(key in values)) return fallback;
    const value = Number(values[key]);
    if (!Number.isInteger(value) || value < 1 || value > max) throw new Error('--' + key + ' doit être compris entre 1 et ' + max);
    return value;
  };
  const limits = {};
  for (const dimension of ['task', 'agent', 'cycle', 'night']) {
    const amount = integer(dimension + '-tokens', null, 1_000_000_000);
    if (amount !== null) limits[dimension] = amount;
  }
  if (values.mode && !['eco', 'normal', 'max'].includes(values.mode)) throw new Error('Modes acceptés : eco, normal, max');
  if (values.background && !['start','resume'].includes(command)) throw new Error('--background est réservé à start et resume.');
  return { command, background: Boolean(values.background), config: {
    workers: integer('workers', 2, 4),
    minutes: integer('minutes', values.night ? 360 : 60, 720),
    taskMinutes: integer('task-minutes', 35, 240),
    attempts: integer('attempts', 2, 8),
    maxBytes: integer('snapshot-mb', 512, 4096) * 1024 * 1024,
    codex: values.codex,
    supplied: Object.keys(values),
    policy: { ...(values.mode ? { mode: values.mode } : {}), limits, ...(values.night ? { session: 'night' } : {}) },
  } };
}

function command(executable, args, cwd, encoding = 'utf8') {
  return spawnSync(executable, args, {
    cwd, encoding, windowsHide: true, timeout: 25_000, maxBuffer: 16 * 1024 * 1024,
  });
}

function git(cwd, args, encoding = 'utf8') {
  const r = command('git', ['-c', 'core.hooksPath=' + (windows ? 'NUL' : '/dev/null'), ...args], cwd, encoding);
  if (r.status !== 0) throw new Error('Git ' + args[0] + ' : ' + String(r.stderr || r.error || r.stdout).trim());
  return r.stdout;
}

function ignored(name) {
  const lower = name.toLowerCase();
  return excluded.has(lower) || lower.startsWith('.env') || /(?:credentials|secrets)\.(?:json|ya?ml|toml)$/.test(lower)
    || /\.(?:pem|pfx|key|p12)$/.test(lower) || (name.startsWith('.') && !['.gitignore', '.gdignore', '.gitattributes'].includes(name));
}

function allowedPath(path) {
  return typeof path === 'string' && !path.includes('\\') && !path.includes('\0') && !path.includes(':')
    && !isAbsolute(path) && path.split('/').every(part => part && part !== '.' && part !== '..' && !ignored(part));
}

function getTasks() {
  const raw = read(join(root, 'studio', 'tasks.json'));
  const tasks = Array.isArray(raw) ? raw : raw?.tasks;
  if (!Array.isArray(tasks)) throw new Error('studio/tasks.json doit contenir une liste de tâches.');
  const ids = new Set();
  for (const task of tasks) {
    if (!task || typeof task.id !== 'string' || !safePart(task.id) || ids.has(task.id) || !priorities.has(task.priority)
      || typeof task.title !== 'string' || !task.title.trim() || typeof task.instructions !== 'string' || !task.instructions.trim()
      || !Array.isArray(task.files) || !task.files.length || !task.files.every(allowedPath)) {
      throw new Error('Mission invalide : ' + String(task?.id));
    }
    if (!Array.isArray(task.checks) || !task.checks.every(check => typeof check?.command === 'string' && check.command
      && Array.isArray(check.args) && check.args.every(arg => typeof arg === 'string'))) {
      throw new Error('Commandes de validation invalides : ' + task.id);
    }
    ids.add(task.id);
  }
  for (const task of tasks) {
    task.dependsOn ??= [];
    if (!Array.isArray(task.dependsOn) || task.dependsOn.some(id => !ids.has(id))) throw new Error('Dépendance inconnue : ' + task.id);
    const parents = new Set([task.id]);
    const inspect = id => {
      if (parents.has(id)) throw new Error('Cycle de dépendance : ' + task.id);
      parents.add(id);
      for (const dep of tasks.find(t => t.id === id).dependsOn ?? []) inspect(dep);
      parents.delete(id);
    };
    for (const parent of task.dependsOn) inspect(parent);
  }
  return tasks.sort((a, b) => a.priority.localeCompare(b.priority));
}

function findCodex(config) {
  if (config.codex) {
    if (!isAbsolute(config.codex) || !existsSync(config.codex)) throw new Error('--codex doit désigner un exécutable ou fichier JS absolu.');
    return /\.[cm]?js$/i.test(config.codex)
      ? { executable: process.execPath, prefix: [config.codex] } : { executable: config.codex, prefix: [] };
  }
  if (windows && process.env.APPDATA) {
    const packageRoot = join(process.env.APPDATA, 'npm', 'node_modules', '@openai', 'codex');
    const arch = process.arch === 'arm64' ? 'aarch64' : 'x86_64';
    const platformPackage = process.arch === 'arm64' ? 'codex-win32-arm64' : 'codex-win32-x64';
    const native = join(packageRoot, 'node_modules', '@openai', platformPackage, 'vendor', arch + '-pc-windows-msvc', 'bin', 'codex.exe');
    if (existsSync(native)) return { executable: native, prefix: [] };
    const entry = join(packageRoot, 'bin', 'codex.js');
    if (existsSync(entry)) return { executable: process.execPath, prefix: [entry] };
  }
  return { executable: windows ? 'codex.exe' : 'codex', prefix: [] };
}

function preflight(config) {
  const gitVersion = command('git', ['--version'], root);
  if (gitVersion.status !== 0) throw new Error('Git indisponible : ' + (gitVersion.error?.message || gitVersion.stderr));
  const codex = findCodex(config);
  const cli = command(codex.executable, [...codex.prefix, '--version'], root);
  if (cli.status !== 0) throw new Error('Codex CLI indisponible : ' + (cli.error?.message || cli.stderr));
  const auth = command(codex.executable, [...codex.prefix, 'login', 'status'], root);
  if (auth.status !== 0) throw new Error('Session Codex non vérifiable : ' + (auth.error?.message || (auth.stderr + ' ' + auth.stdout).trim()));
  return { ...codex, version: String(cli.stdout).trim() };
}

function alive(pid) {
  if (!Number.isInteger(pid) || pid < 1) return false;
  try { process.kill(pid, 0); return true; }
  catch (error) { return error.code === 'EPERM'; }
}

function lock() {
  mkdirSync(studio, { recursive: true });
  try {
    const fd = openSync(lockPath, 'wx');
    try { writeFileSync(fd, JSON.stringify({ pid: process.pid, at: timestamp() })); }
    finally { closeSync(fd); }
  } catch (error) {
    if (error.code === 'EEXIST') throw new Error('Un verrou existe. Vérifie status ou exécute recover pour un arrêt inattendu.');
    throw error;
  }
}

function snapshot(integration, maxBytes) {
  mkdirSync(integration, { recursive: true });
  let bytes = 0;
  function copy(source, target) {
    for (const entry of readdirSync(source, { withFileTypes: true })) {
      if (ignored(entry.name) || entry.isSymbolicLink()) continue;
      const from = join(source, entry.name);
      const to = join(target, entry.name);
      if (entry.isDirectory()) {
        mkdirSync(to);
        copy(from, to);
      } else if (entry.isFile()) {
        bytes += statSync(from).size;
        if (bytes > maxBytes) throw new Error('Taille du snapshot supérieure à la limite configurée.');
        copyFileSync(from, to);
      }
    }
  }
  copy(root, integration);
  git(integration, ['init', '-b', 'validated']);
  git(integration, ['config', 'user.email', 'studio@local.invalid']);
  git(integration, ['config', 'user.name', 'Keravel Studio']);
  git(integration, ['config', 'core.autocrlf', 'false']);
  git(integration, ['add', '-A']);
  git(integration, ['commit', '-m', 'Snapshot local du studio']);
  return bytes;
}

function taskScope(task, file) {
  return task.files.some(path => path === file || file.startsWith(path + '/'));
}

function changedFiles(cwd, base) {
  const fields = raw => raw.split('\0').filter(Boolean);
  const tracked = fields(git(cwd, ['diff', '--name-only', '-z', '--no-renames', base, '--']));
  const extra = fields(git(cwd, ['ls-files', '-o', '--exclude-standard', '-z']));
  return [...new Set([...tracked, ...extra])];
}

function spawnLogged(executable, args, cwd, log, onLine) {
  const child = spawn(executable, args, { cwd, windowsHide: true, stdio: ['pipe', 'pipe', 'pipe'] });
  let buffer = '';
  child.stdout.setEncoding('utf8');
  child.stderr.setEncoding('utf8');
  child.stdout.on('data', chunk => {
    appendFileSync(log, chunk);
    if (!onLine) return;
    buffer += chunk;
    const parts = buffer.split(/\r?\n/);
    buffer = parts.pop();
    for (const line of parts) onLine(line);
  });
  child.stderr.on('data', chunk => appendFileSync(log, chunk));
  const done = new Promise(resolveResult => {
    let failure;
    child.on('error', error => { failure = error.message; appendFileSync(log, '\n' + failure + '\n'); });
    child.once('close', (code, signal) => {
      if (onLine && buffer) onLine(buffer);
      resolveResult({ code, signal, failure });
    });
  });
  child.stdin.on('error', () => {});
  return { child, done };
}

function terminate(child) {
  if (!child?.pid || child.exitCode !== null || child.signalCode || !alive(child.pid)) return;
  if (windows) {
    const result = command('taskkill.exe', ['/PID', String(child.pid), '/T', '/F'], root);
    if (result.status !== 0 && child.exitCode === null) child.kill();
  } else {
    child.kill('SIGTERM');
    const escalation = setTimeout(() => {
      if (child.exitCode === null && !child.signalCode && alive(child.pid)) child.kill('SIGKILL');
    }, 4000);
    escalation.unref();
  }
}

function sampleProcesses(pids) {
  if (windows) {
    const script = 'Get-Process -Id ' + pids.join(',') + ' -ErrorAction SilentlyContinue | '
      + 'Select-Object Id,CPU,WorkingSet64 | ConvertTo-Json -Compress';
    const result = command('powershell.exe', ['-NoProfile', '-NonInteractive', '-Command', script], root);
    if (result.status !== 0 || !result.stdout.trim()) return [];
    try {
      const entries = JSON.parse(result.stdout.replace(/^\uFEFF/, '').trim());
      return [entries].flat().filter(Boolean).map(row => ({ pid: row.Id, cpuMs: Number(row.CPU) * 1000, rssBytes: row.WorkingSet64 }));
    } catch { return []; }
  }
  return pids.flatMap(pid => {
    try {
      const rss = readFileSync('/proc/' + pid + '/status', 'utf8').match(/^VmRSS:\s+(\d+) kB/m);
      return rss ? [{ pid, rssBytes: Number(rss[1]) * 1024 }] : [];
    } catch { return []; }
  });
}

function compactMemory(mode) {
  const memory = join(root, 'PROJECT_MEMORY.md');
  if (!existsSync(memory)) return '';
  const max = mode === 'max' ? 12_000 : (mode === 'normal' ? 7_000 : 3_400);
  return readFileSync(memory, 'utf8').slice(0, max);
}

function makePrompt(task, mode) {
  return [
    'Mission de production du studio Keravel. Mode ' + mode + '.',
    'Mission ' + task.id + ' : ' + task.title,
    task.instructions,
    MODES[mode],
    'Fichiers autorisés : ' + task.files.join(', '),
    'Vérifications prévues : ' + JSON.stringify(task.checks),
    'Travaille uniquement dans ton lot. Ne crée aucun commit. Ne publie rien. Ne lance pas de sous-agent.',
    'Réutilise les notes et les outils existants, effectue les validations utiles et évite les sorties volumineuses.',
    'Après les modifications, rends un rapport bref en quatre lignes : Fichiers, Résultat, Tests, Blocages.',
    compactMemory(mode),
  ].join('\n\n');
}

function report(state) {
  if (!state) return '# Rapport du studio Keravel\n\nAucun cycle démarré. Aucun agent, test ou changement mesuré.\n';
  const rows = [];
  const attempts = Object.values(state.tasks).flatMap(task => task.attempts);
  const started = attempts.filter(a => a.spawned).length;
  const worked = attempts.reduce((sum, a) => sum + (a.spawned && a.elapsedMs ? a.elapsedMs : 0), 0);
  const cpu = state.managerMetrics?.cpuMs;
  const memory = state.managerMetrics?.maxRssKiB;
  const measurements = cpu !== undefined ? 'CPU superviseur ' + Math.round(cpu) + ' ms, RSS maximale du superviseur ' + Math.round(memory / 1024) + ' Mio.' : 'Télémétrie du superviseur indisponible.';
  for (const [id, task] of Object.entries(state.tasks)) {
    const last = task.attempts.at(-1);
    const lines = ['### ' + task.priority + ' · ' + id + ' · ' + task.status, '', task.title];
    if (task.reason) lines.push('', 'État : ' + task.reason);
    if (last) {
      lines.push('Tentatives : ' + task.attempts.length);
      if (last.created?.length) lines.push('Fichiers créés : ' + last.created.join(', '));
      if (last.modified?.length) lines.push('Fichiers modifiés : ' + last.modified.join(', '));
      if (last.deleted?.length) lines.push('Fichiers supprimés dans le lot isolé : ' + last.deleted.join(', '));
      if (last.patch) lines.push('Patch à examiner : ' + last.patch);
      for (const check of last.checks ?? []) lines.push('Test ' + (check.ok ? 'réussi' : 'échoué') + ' : ' + check.name);
      if (last.log) lines.push('Journal : ' + last.log);
      if (last.report && existsSync(join(root, last.report))) lines.push('Rapport de l’agent (déclaratif) : ' + last.report);
      if (last.usage?.length) {
        const tokens = last.usage.reduce((sum, u) => sum + u.input_tokens + u.output_tokens, 0);
        lines.push('Jetons constatés : ' + tokens);
      } else if (last.spawned) lines.push('Jetons non mesurés par la CLI pour cette tentative.');
      if (last.alerts?.length) lines.push('Alertes budget : ' + last.alerts.join(' · '));
      if (last.resources?.peakRssBytes) {
        const rss = Math.round(last.resources.peakRssBytes / 1048576);
        const cpuText = Number.isFinite(last.resources.cpuMs) ? ' · CPU observé ' + Math.round(last.resources.cpuMs) + ' ms' : '';
        lines.push('Mémoire RSS observée du processus du lot : ' + rss + ' Mio' + cpuText);
      }
    }
    rows.push(lines.join('\n'));
  }
  return [
    '# Rapport du studio Keravel', '', 'Cycle ' + state.id + ' · ' + state.status,
    '', 'Agents démarrés : ' + started + '. Durée cumulée mesurée des agents terminés : ' + seconds(worked) + ' s.',
    'Début : ' + state.started + (state.ended ? ' · Fin : ' + state.ended : ''),
    'Mode ' + state.policy?.mode + ' · Durée maximale ' + state.config?.minutes + ' min · ' + state.config?.workers + ' agents simultanés au plus.',
    measurements + ' GPU : mesures indisponibles. Chaque lot indique ses mesures de processus lorsqu’elles sont disponibles.',
    'Intégration dans le snapshot isolé du studio. Aucun déploiement automatique.',
    state.reason ? 'Motif : ' + state.reason : '',
    '', '## Tâches, vérifications et travaux à reprendre', '', ...rows.flatMap(row => [row, '']),
    'Les bâtiments et effets visuels restent déclaratifs jusqu’à examen des captures et rapports de validation.',
  ].join('\n') + '\n';
}

function updateReport(state) {
  writeFileSync(reportPath, report(state));
}

function checkpoint(state) {
  const metrics = process.resourceUsage();
  state.updated = timestamp();
  state.managerMetrics = { cpuMs: (metrics.userCPUTime + metrics.systemCPUTime) / 1000, maxRssKiB: metrics.maxRSS };
  write(statePath, state);
}

function status(state) {
  if (!state) {
    console.log('Aucun cycle du studio.');
    return;
  }
  const active = read(lockPath);
  console.log('Cycle ' + state.id + ' — ' + state.status + ' · superviseur ' + (active && alive(active.pid) ? 'PID ' + active.pid + ' vérifié' : 'arrêté ou non vérifiable'));
  if (state.reason) console.log(state.reason);
  for (const [id, task] of Object.entries(state.tasks)) {
    const last = task.attempts.at(-1);
    const live = ['running', 'checking'].includes(task.status) && alive(last?.pid);
    console.log(task.priority + ' ' + id + ' : ' + task.status + (live ? ' (PID ' + last.pid + ' présent)' : '') + (task.reason ? ' — ' + task.reason : ''));
  }
}

function recover(state) {
  const active = read(lockPath);
  if (active && alive(active.pid)) throw new Error('Superviseur encore détecté. Utilise status, pause ou stop.');
  const interrupted = Object.values(state?.tasks ?? {}).filter(task => ['running', 'checking'].includes(task.status));
  if (interrupted.some(task => alive(task.attempts.at(-1)?.pid))) {
    throw new Error('Un PID de travail reste présent. Vérifie-le avant de reprendre ; aucun processus incertain n’a été interrompu.');
  }
  const integration = state && safePart(state.id) ? join(studio, 'runs', state.id, 'integration') : null;
  if (integration && existsSync(join(integration, '.git', 'CHERRY_PICK_HEAD'))) {
    git(integration, ['cherry-pick', '--abort']);
  }
  for (const task of interrupted) {
    const attempt = task.attempts.at(-1);
    if (integration && /^[0-9a-f]{40,64}$/.test(attempt.commit ?? '') && existsSync(join(integration, '.git'))) {
      const validated = git(integration, ['log', '--format=%H', '-1', '--fixed-strings', '--grep=(cherry picked from commit ' + attempt.commit + ')']).trim();
      if (validated) {
        attempt.validatedCommit = validated;
        attempt.outcome = 'validated';
        task.status = 'validated';
        task.reason = 'Intégration privée retrouvée après interruption.';
        continue;
      }
    }
    task.status = 'pending';
    task.reason = 'Tentative interrompue, espace de travail conservé.';
    attempt.outcome = 'interrupted';
    attempt.pid = null;
  }
  if (existsSync(lockPath)) rmSync(lockPath);
  if (state && (interrupted.length || state.status === 'running')) {
    state.status = 'interrupted';
    checkpoint(state);
    updateReport(state);
  }
  console.log('Récupération terminée. Les tâches interrompues sont à reprendre.');
}

function usageCount(attempt) {
  if (!attempt.usage.length) return null;
  return attempt.usage.reduce((total, item) => total + item.input_tokens + item.output_tokens, 0);
}

function measure(state, job, attempt) {
  const sum = attempts => {
    const values = attempts.map(usageCount).filter(value => value !== null);
    return values.length ? values.reduce((a, b) => a + b, 0) : null;
  };
  const all = Object.values(state.tasks).flatMap(task => task.attempts);
  const task = job ? sum(state.tasks[job.id].attempts) : null;
  const cycle = sum(all);
  const previous = state.previousNightTokens ?? null;
  return { task, agent: attempt ? usageCount(attempt) : null, cycle, night: previous === null ? cycle : previous + (cycle ?? 0) };
}

function resumeConfig(saved, requested) {
  const options = { workers: 'workers', minutes: 'minutes', taskMinutes: 'task-minutes',
    attempts: 'attempts', maxBytes: 'snapshot-mb', codex: 'codex' };
  const current = { ...saved, supplied: requested.supplied };
  for (const [key, cli] of Object.entries(options)) {
    if (requested.supplied.includes(cli)) current[key] = requested[key];
  }
  current.policy = { ...saved.policy, ...requested.policy, limits: { ...saved.policy.limits, ...requested.policy.limits } };
  return current;
}

async function run(config, resume) {
  let state = read(statePath);
  if (resume && read(lockPath) && alive(read(lockPath).pid)) {
    write(controlPath, { cycle: state?.id, action: 'run', at: timestamp() });
    console.log('Reprise demandée au superviseur.');
    return;
  }
  lock();
  const active = new Map();
  let signal = '';
  const stop = () => { signal = 'stop'; };
  process.on('SIGINT', stop);
  process.on('SIGTERM', stop);
  try {
    const queue = getTasks();
    const reuse = Boolean(state && resume && ['paused','stopped','interrupted','blocked','budget','time'].includes(state.status));
    if (reuse && state.config) config = resumeConfig(state.config, config);
    const policy = loadPolicy(root, config.policy);
    const previousNightTokens = state?.policy?.session === 'night' && Date.now() - Date.parse(state.started) < 12 * 60 * 60_000
      ? measure(state).night : null;
    if (!reuse) {
      if (Object.values(state?.tasks ?? {}).some(t => ['running', 'checking'].includes(t.status))) throw new Error('Des tâches sont interrompues. Exécute recover puis resume.');
      state = { id: timestamp().replace(/[:.]/g, '-') + '-' + randomUUID().slice(0, 8), started: timestamp(),
        status: 'starting', config, policy, previousNightTokens, tasks: {} };
      for (const task of queue) state.tasks[task.id] = { title: task.title, priority: task.priority, status: 'pending', attempts: [] };
    } else {
      state.policy = policy;
      state.config = config;
      for (const task of queue) state.tasks[task.id] ??= { title: task.title, priority: task.priority, status: 'pending', attempts: [] };
    }
    const at = Date.now();
    const deadline = at + config.minutes * 60_000;
    const cycle = join(studio, 'runs', state.id);
    const integration = join(cycle, 'integration');
    const logPath = join(cycle, 'manager.log');
    mkdirSync(cycle, { recursive: true });
    const record = message => appendFileSync(logPath, timestamp() + ' ' + message + '\n');
    const persist = () => checkpoint(state);
    state.reason = '';
    persist();

    let launcher;
    try {
      launcher = preflight(config);
      state.codex = launcher.version;
      if (!existsSync(join(integration, '.git'))) {
        const staging = join(cycle, 'snapshot-' + randomUUID());
        state.snapshotBytes = snapshot(staging, config.maxBytes);
        renameSync(staging, integration);
      }
    } catch (error) {
      state.status = 'blocked';
      state.reason = error.message;
      state.ended = timestamp();
      record(state.reason);
      persist();
      updateReport(state);
      console.error(state.reason);
      process.exitCode = 1;
      return;
    }

    state.status = 'running';
    delete state.ended;
    write(controlPath, { cycle: state.id, action: 'run', at: timestamp() });
    persist();

    async function work(job, attempt, mode) {
      const entry = state.tasks[job.id];
      const holder = active.get(job.id);
      const path = join(cycle, job.id + '-' + entry.attempts.length + '-' + randomUUID().slice(0, 8));
      mkdirSync(path);
      const cwd = join(path, 'checkout');
      const log = join(path, 'execution.log');
      const final = join(path, 'agent.md');
      attempt.log = relative(root, log);
      attempt.report = relative(root, final);
      attempt.checkout = relative(root, cwd);
      attempt.mode = mode;
      const base = git(integration, ['rev-parse', 'HEAD']).trim();
      attempt.base = base;
      git(integration, ['worktree', 'add', '--detach', cwd, base]);
      const onLine = line => {
        const observed = readUsage(line);
        if (observed) {
          attempt.usage.push(observed);
          const decision = budgetDecision(policy, measure(state, job, attempt), job, mode);
          attempt.alerts = decision.alerts;
          for (const alert of decision.alerts) record('Budget ' + job.id + ' : ' + alert);
          persist();
        }
      };
      const run = spawnLogged(launcher.executable, [
        ...launcher.prefix, '-a', 'never', 'exec', '--sandbox', 'workspace-write',
        '--json', '--color', 'never', '--output-last-message', final, '-',
      ], cwd, log, onLine);
      holder.child = run.child;
      run.child.once('spawn', () => {
        attempt.spawned = true;
        attempt.started = timestamp();
        attempt.pid = run.child.pid;
        record('Agent réel démarré ' + job.id + ' PID ' + attempt.pid);
        persist();
      });
      run.child.stdin.end(makePrompt(job, mode));
      const result = await run.done;
      if (attempt.started) attempt.elapsedMs = Math.max(0, Date.now() - Date.parse(attempt.started));
      attempt.pid = null;
      if (holder.cancel) throw new Error(holder.cancel);
      if (result.failure || result.code !== 0) throw new Error('Codex a échoué : ' + (result.failure || result.code || result.signal));
      if (git(cwd, ['rev-parse', 'HEAD']).trim() !== base) throw new Error('Le lot a modifié son HEAD.');
      const changed = changedFiles(cwd, base);
      const outside = changed.filter(file => !allowedPath(file) || !taskScope(job, file));
      if (outside.length) throw new Error('Fichiers hors lot : ' + outside.join(', '));
      if (!changed.length) throw new Error('Aucune modification livrée par l’agent.');
      entry.status = 'checking';
      persist();
      for (const check of job.checks) {
        const checkName = [check.command, ...check.args].join(' ');
        const validation = spawnLogged(check.command, check.args, cwd, log);
        holder.child = validation.child;
        attempt.pid = validation.child.pid;
        persist();
        validation.child.stdin.end();
        const resultCheck = await validation.done;
        attempt.pid = null;
        attempt.checks.push({ name: checkName, ok: resultCheck.code === 0 && !resultCheck.failure });
        if (holder.cancel) throw new Error(holder.cancel);
        if (resultCheck.code !== 0 || resultCheck.failure) throw new Error('Échec du test : ' + checkName);
      }
      const finalChanges = changedFiles(cwd, base);
      if (finalChanges.some(file => !allowedPath(file) || !taskScope(job, file))) throw new Error('Une validation a modifié un fichier hors lot.');
      if (!finalChanges.length) throw new Error('Aucune modification ne subsiste après validation.');
      if (finalChanges.some(file => existsSync(join(cwd, file)) && !lstatSync(join(cwd, file)).isFile())) {
        throw new Error('Le lot contient un fichier non ordinaire.');
      }
      const tracked = new Set(git(cwd, ['ls-files', '-z']).split('\0'));
      attempt.created = finalChanges.filter(file => !tracked.has(file));
      attempt.modified = finalChanges.filter(file => tracked.has(file) && existsSync(join(cwd, file)));
      attempt.deleted = finalChanges.filter(file => tracked.has(file) && !existsSync(join(cwd, file)));
      if (attempt.deleted.length && !job.allowDeletion) throw new Error('Ce lot ne prévoit pas de suppression de fichier.');
      git(cwd, ['add', '--all', '--', ...finalChanges]);
      git(cwd, ['diff', '--cached', '--check']);
      git(cwd, ['commit', '-m', job.title]);
      attempt.commit = git(cwd, ['rev-parse', 'HEAD']).trim();
      const patch = join(path, 'review.patch');
      writeFileSync(patch, git(cwd, ['format-patch', '-1', '--stdout'], null));
      attempt.patch = relative(root, patch);
      persist();
      try { git(integration, ['cherry-pick', '-x', attempt.commit]); }
      catch (error) {
        if (existsSync(join(integration, '.git', 'CHERRY_PICK_HEAD'))) git(integration, ['cherry-pick', '--abort']);
        throw error;
      }
      attempt.validatedCommit = git(integration, ['rev-parse', 'HEAD']).trim();
      entry.status = 'validated';
      entry.reason = 'Lot vérifié et intégré dans le snapshot de travail.';
      attempt.outcome = 'validated';
      record('Lot validé ' + job.id + ' ' + attempt.validatedCommit);
    }

    const schedule = job => {
      const entry = state.tasks[job.id];
      const attempt = { queuedAt: timestamp(), checks: [], usage: [], outcome: 'running' };
      const mode = selectMode(policy, job);
      const holder = { job, child: null, expires: Date.now() + config.taskMinutes * 60_000, cancel: '' };
      active.set(job.id, holder);
      entry.status = 'running';
      entry.reason = '';
      entry.attempts.push(attempt);
      persist();
      holder.done = work(job, attempt, mode).catch(error => {
        attempt.outcome = holder.retryWithoutPenalty ? 'interrupted' : 'failed';
        entry.reason = error.message;
        const failed = entry.attempts.filter(item => item.outcome === 'failed').length;
        entry.status = failed >= config.attempts ? 'blocked' : 'pending';
        record(job.id + ' ' + attempt.outcome + ' : ' + error.message);
      }).finally(() => {
        attempt.pid = null;
        attempt.ended = timestamp();
        active.delete(job.id);
        persist();
      });
    };

    let action = 'run';
    let lastSample = 0;
    while (true) {
      const control = read(controlPath);
      if (control?.cycle === state.id) action = control.action;
      if (signal) action = signal;
      if (Date.now() >= deadline && action !== 'stop') action = 'time';
      if (active.size && Date.now() - lastSample >= 15_000) {
        lastSample = Date.now();
        const agents = Object.values(state.tasks).filter(task => task.status === 'running')
          .map(task => task.attempts.at(-1))
          .filter(attempt => Number.isInteger(attempt.pid) && attempt.pid > 0);
        const observations = agents.length ? sampleProcesses(agents.map(attempt => attempt.pid)) : [];
        for (const attempt of agents) {
          const data = observations.find(row => row.pid === attempt.pid);
          if (!data || !Number.isFinite(data.rssBytes)) continue;
          const previous = attempt.resources ?? {};
          attempt.resources = {
            peakRssBytes: Math.max(previous.peakRssBytes ?? 0, data.rssBytes),
            cpuMs: Number.isFinite(data.cpuMs) ? Math.max(previous.cpuMs ?? 0, data.cpuMs) : previous.cpuMs,
          };
        }
        persist();
      }
      for (const holder of active.values()) {
        if (!holder.cancel && (action === 'stop' || action === 'time' || Date.now() >= holder.expires)) {
          holder.cancel = action === 'stop' ? 'Arrêt demandé.' : 'Durée maximale atteinte.';
          holder.retryWithoutPenalty = action === 'stop' || action === 'time';
          terminate(holder.child);
        }
      }
      if (action === 'run') {
        for (const job of queue) {
          if (job.enabled === false) continue;
          const entry = state.tasks[job.id];
          if (entry.status !== 'pending' || !job.dependsOn.every(dep => state.tasks[dep]?.status === 'validated')) continue;
          if ([...active.values()].some(holder => holder.job.files.some(path => taskScope(job, path) || job.files.some(own => own.startsWith(path + '/'))))) continue;
          const mode = selectMode(policy, job);
          const decision = budgetDecision(policy, measure(state, job), job, mode);
          if (decision.stop) {
            entry.reason = (decision.alerts ?? []).join(' · ') || 'Budget observé atteint.';
            continue;
          }
          if (active.size >= (decision.optimize ? 1 : config.workers)) break;
          schedule(job);
        }
      }
      if (!active.size) {
        if (action !== 'run') state.status = action === 'pause' ? 'paused' : (action === 'time' ? 'time' : 'stopped');
        else {
          const remaining = queue.filter(job => job.enabled !== false && state.tasks[job.id].status !== 'validated');
          state.status = remaining.length ? 'blocked' : 'complete';
          for (const job of remaining) {
            const entry = state.tasks[job.id];
            if (!entry.reason && entry.status === 'pending') entry.reason = 'Dépendances en attente : ' + job.dependsOn.filter(dep => state.tasks[dep].status !== 'validated').join(', ');
          }
        }
        break;
      }
      await new Promise(resolveTick => setTimeout(resolveTick, 800));
    }
    state.ended = timestamp();
    persist();
    updateReport(state);
    status(state);
    if (state.status === 'blocked') process.exitCode = 1;
  } catch (error) {
    for (const holder of active.values()) {
      holder.cancel = error.message;
      terminate(holder.child);
    }
    await Promise.allSettled([...active.values()].map(holder => holder.done));
    if (state) {
      state.status = 'blocked';
      state.reason = error.message;
      checkpoint(state);
      updateReport(state);
    }
    throw error;
  } finally {
    process.off('SIGINT', stop);
    process.off('SIGTERM', stop);
    if (existsSync(lockPath)) rmSync(lockPath);
  }
}

async function main() {
  const { command: subcommand, background, config } = parse(process.argv.slice(2));
  if (background) {
    mkdirSync(studio, { recursive: true });
    const log = join(studio, 'launcher.log');
    const fd = openSync(log, 'a');
    let child;
    try {
      child = spawn(process.execPath, [fileURLToPath(import.meta.url), ...process.argv.slice(2).filter(arg => arg !== '--background')], {
        cwd: root, detached: true, windowsHide: true, stdio: ['ignore', fd, fd],
      });
    } finally { closeSync(fd); }
    await new Promise((resolveLaunch, reject) => {
      child.once('spawn', resolveLaunch);
      child.once('error', reject);
    });
    child.unref();
    console.log('Lanceur PID ' + child.pid + ' démarré. Vérifie le superviseur avec status. Journal : ' + log);
    return;
  }
  const state = read(statePath);
  switch (subcommand) {
    case 'status': status(state); break;
    case 'report': updateReport(state); console.log(reportPath); break;
    case 'recover': recover(state); break;
    case 'start': await run(config, false); break;
    case 'resume': await run(config, true); break;
    case 'pause':
    case 'stop': {
      const owner = read(lockPath);
      if (!state || !owner || !alive(owner.pid)) throw new Error('Aucun superviseur en cours.');
      write(controlPath, { cycle: state.id, action: subcommand, at: timestamp() });
      console.log(subcommand === 'pause' ? 'Pause demandée. Les lots en cours sont validés avant la pause.' : 'Arrêt demandé.');
      break;
    }
  }
}

try {
  await main();
} catch (failure) {
  console.error(failure.message);
  process.exitCode = 1;
}
