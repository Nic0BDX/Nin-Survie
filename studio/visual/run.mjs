import { spawn, spawnSync } from 'node:child_process';
import { createWriteStream } from 'node:fs';
import { mkdir, readFile, readdir, stat, writeFile } from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const directory = path.dirname(fileURLToPath(import.meta.url));
const project = path.resolve(directory, '../..');
const reports = path.join(directory, 'reports');
const assetSuffixes = new Set(['.png', '.jpg', '.jpeg', '.webp', '.svg', '.ogg', '.wav', '.mp3', '.glb', '.gltf', '.ktx2', '.tscn']);
const excluded = new Set(['.git', '.godot', '.vercel', 'dist', 'node_modules', 'studio']);

function options(args) {
  const allowed = new Set(['--version', '--godot', '--baseline', '--threshold', '--timeout-ms']);
  const flags = {};
  for (let i = 0; i < args.length; i += 2) {
    if (!allowed.has(args[i]) || !args[i + 1] || args[i + 1].startsWith('--')) {
      throw Error('Usage : node studio/visual/run.mjs --version <id> [--godot <exécutable>] [--baseline <id>] [--threshold <0-1>] [--timeout-ms <ms>]');
    }
    flags[args[i].slice(2)] = args[i + 1];
  }
  const validSlug = value => typeof value === 'string' && /^[a-z0-9][a-z0-9._-]{0,65}$/i.test(value);
  if (!validSlug(flags.version) || (flags.baseline && !validSlug(flags.baseline))) {
    throw Error('Les identifiants de version doivent contenir uniquement lettres, chiffres, points, tirets et soulignements.');
  }
  if (flags.version === flags.baseline) throw Error('La version et sa référence doivent être différentes.');
  flags.threshold = Number(flags.threshold ?? '0.045');
  flags.timeout = Number(flags['timeout-ms'] ?? '180000');
  if (!Number.isFinite(flags.threshold) || flags.threshold < 0 || flags.threshold > 1) throw Error('Seuil visuel invalide.');
  if (!Number.isSafeInteger(flags.timeout) || flags.timeout < 5000 || flags.timeout > 900000) throw Error('Délai invalide (5000 à 900000 ms).');
  return flags;
}

function locateGodot(explicit) {
  const configured = explicit ?? process.env.GODOT_BIN;
  for (const candidate of configured ? [configured] : ['godot4', 'godot']) {
    const check = spawnSync(candidate, ['--version'], { encoding: 'utf8', windowsHide: true, timeout: 10000, cwd: project });
    if (!check.error && check.status === 0 && /^4\./.test(check.stdout.trim())) {
      return { command: candidate, version: check.stdout.trim() };
    }
  }
  return null;
}

function hostSample() {
  return os.cpus().reduce((sum, cpu) => {
    const times = cpu.times;
    sum.busy += times.user + times.nice + times.sys + times.irq;
    sum.total += Object.values(times).reduce((a, b) => a + b, 0);
    return sum;
  }, { busy: 0, total: 0 });
}

async function scanAssets(root) {
  let count = 0;
  let bytes = 0;
  const largest = [];
  async function walk(folder) {
    for (const item of await readdir(folder, { withFileTypes: true })) {
      if (excluded.has(item.name) || item.isSymbolicLink()) continue;
      const full = path.join(folder, item.name);
      if (item.isDirectory()) await walk(full);
      else if (item.isFile() && assetSuffixes.has(path.extname(item.name).toLowerCase())) {
        const size = (await stat(full)).size;
        count++;
        bytes += size;
        largest.push({ file: path.relative(root, full).split(path.sep).join('/'), bytes: size });
      }
    }
  }
  await walk(root);
  return { count, bytes, largest: largest.sort((a, b) => b.bytes - a.bytes).slice(0, 8) };
}

async function run(godot, args, output, timeout, environment) {
  const log = createWriteStream(output);
  const started = Date.now();
  return new Promise((resolve, reject) => {
    log.on('error', reject);
    const child = spawn(godot, args, { cwd: project, env: environment, windowsHide: true, stdio: ['ignore', 'pipe', 'pipe'] });
    child.stdout.pipe(log, { end: false });
    child.stderr.pipe(log, { end: false });
    let expired = false;
    let error = null;
    child.on('error', err => { error = err.message; });
    const timer = setTimeout(() => {
      expired = true;
      child.kill('SIGKILL');
    }, timeout);
    child.once('close', (code, signal) => {
      clearTimeout(timer);
      log.end(() => resolve({ code, signal, expired, error, ms: Date.now() - started }));
    });
  });
}

const unavailable = 'indisponible';
const shown = value => value == null ? unavailable : String(value);

function markdown(state) {
  const rows = [
    '# Rapport visuel Keravel', '',
    'Version ' + state.version + ' · ' + state.utc,
    'État **' + state.status + '**', '', state.reason, '',
    '## Exécution', '',
    '- Moteur ' + shown(state.godot),
    '- Durée du contrôle ' + state.elapsed_ms + ' ms',
    '- Chargement de la scène ' + (state.engine?.scene_load_ms == null ? unavailable : state.engine.scene_load_ms + ' ms'),
    '- Adaptateur graphique ' + shown(state.engine?.adapter),
    '- Utilisation CPU de l’hôte pendant le contrôle ' + (state.host_cpu_percent == null ? unavailable : state.host_cpu_percent.toFixed(1) + ' %'),
    '- Sources d’assets mesurées ' + state.assets.count + ' fichiers · ' + state.assets.bytes + ' octets',
  ];
  if (state.stages.import) rows.push('- Import [journal](import.log)');
  if (state.stages.capture) rows.push('- Rendu [journal](capture.log)');
  if (state.engine?.captures?.length) {
    rows.push('', '## Captures', '', '| Vue | Image | Comparaison RGB | FPS | CPU image ms | Primitives | Objets visibles | Appels | Mémoire moteur et GPU | PNJ instrumentés |', '|---|---|---|---:|---:|---:|---:|---:|---|---:|');
    for (const view of state.engine.captures) {
      const cm = view.comparison;
      const m = view.metrics ?? {};
      const detail = cm?.mean_rgb_error == null ? shown(cm?.status) : cm.status + ' ' + (cm.mean_rgb_error * 100).toFixed(2) + ' %';
      rows.push('| ' + view.id + ' | ' + (view.file ? '[PNG](' + view.file + ') · ' + view.status : view.status) + ' | ' + detail +
        ' | ' + [m.fps, m.frame_process_ms, m.rendered_primitives, m.visible_render_objects, m.draw_calls].map(shown).join(' | ') +
        ' | ' + shown(m.engine_memory_bytes) + ' / ' + shown(m.gpu_memory_bytes) + ' | ' + shown(m.active_tagged_npcs) + ' |');
    }
  }
  if (state.assets.largest.length) {
    rows.push('', '## Assets les plus lourds', '');
    for (const asset of state.assets.largest) rows.push('- `' + asset.file + '` · ' + asset.bytes + ' octets');
  }
  rows.push('', '## Portée', '',
    'Les caméras fixes mesurent la dérive des pixels. La qualité des intérieurs, des collisions et de l’implantation se vérifie dans la scène. Les primitives rendent compte des passes de rendu. La mesure CPU concerne l’hôte complet. La mémoire système du processus Godot et le taux d’occupation GPU ne sont pas instrumentés.',
    '');
  return rows.join('\n');
}

async function main() {
  const flags = options(process.argv.slice(2));
  const folder = path.join(reports, flags.version);
  const baseline = flags.baseline ? path.join(reports, flags.baseline) : '';
  await mkdir(reports, { recursive: true });
  // An existing version is evidence and remains immutable.
  await mkdir(folder);
  await writeFile(path.join(folder, '.gdignore'), '');
  const start = Date.now();
  const initialCpu = hostSample();
  const state = { version: flags.version, utc: new Date().toISOString(), status: 'indisponible', reason: '', godot: null,
    stages: {}, assets: { count: 0, bytes: 0, largest: [] }, engine: null, baseline: flags.baseline ?? null };
  try {
    state.assets = await scanAssets(project);
    const editor = locateGodot(flags.godot);
    if (!editor) {
      state.reason = 'Aucun éditeur Godot 4 utilisable détecté. Indiquer GODOT_BIN ou --godot.';
    } else {
      state.godot = editor.version;
      const qaRoot = path.join(folder, 'userdata');
      await mkdir(qaRoot);
      const environment = { ...process.env, APPDATA: qaRoot, XDG_DATA_HOME: qaRoot, XDG_CONFIG_HOME: qaRoot, XDG_CACHE_HOME: qaRoot };
      const remaining = () => Math.max(1, flags.timeout - (Date.now() - start));
      const imported = state.stages.import = await run(editor.command, ['--headless', '--path', project, '--editor', '--import'],
        path.join(folder, 'import.log'), remaining(), environment);
      const hasErrors = async file => /^\s*(SCRIPT ERROR|ERROR: Failed to load script|ERROR: Parse)/m.test(await readFile(path.join(folder, file), 'utf8'));
      if (imported.expired || imported.code !== 0 || await hasErrors('import.log')) {
        state.status = 'échec';
        state.reason = 'L’import Godot a échoué ou a dépassé le délai.';
      } else {
        const args = ['--path', project, '--windowed', '--resolution', '1440x810', '--audio-driver', 'Dummy',
          '--script', 'res://studio/visual/capture.gd', '--', '--qa', '--visual-out', folder, '--visual-threshold', String(flags.threshold)];
        if (baseline) args.push('--visual-baseline', baseline);
        const captured = state.stages.capture = await run(editor.command, args, path.join(folder, 'capture.log'), remaining(), environment);
        try { state.engine = JSON.parse(await readFile(path.join(folder, 'engine.json'), 'utf8')); } catch {}
        if (!captured.expired && captured.code === 0 && state.engine?.captures?.length && !(await hasErrors('capture.log'))) {
          state.status = baseline ? 'validé' : 'capturé';
          state.reason = baseline ? 'Les captures concordent avec la référence dans le seuil configuré.' : 'Captures obtenues sans référence de comparaison.';
        } else {
          state.status = 'échec';
          state.reason = captured.expired ? 'Le rendu a dépassé le délai.' : 'Le rendu ou la comparaison a échoué. Consulter le journal et les captures disponibles.';
        }
      }
    }
  } catch (error) {
    state.status = 'échec';
    state.reason = error.message;
  }
  const finalCpu = hostSample();
  const totalCpu = finalCpu.total - initialCpu.total;
  state.elapsed_ms = Date.now() - start;
  state.host_cpu_percent = totalCpu > 0 ? Math.max(0, 100 * (finalCpu.busy - initialCpu.busy) / totalCpu) : null;
  await writeFile(path.join(folder, 'status.json'), JSON.stringify(state, null, 2) + '\n');
  await writeFile(path.join(folder, 'REPORT.md'), markdown(state));
  console.log(state.status, path.join(folder, 'REPORT.md'));
  if (state.status === 'indisponible') process.exitCode = 2;
  if (state.status === 'échec') process.exitCode = 1;
}

await main().catch(error => {
  console.error(error.message);
  process.exitCode = 1;
});
