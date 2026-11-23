import { existsSync, readFileSync } from 'node:fs';
import { join } from 'node:path';

export const MODES = Object.freeze({
  eco: 'Lis la mémoire compacte et les fichiers attribués. Réutilise les résultats encore valides. Rapport bref.',
  normal: 'Analyse les dépendances utiles et vérifie les cas limites. Échange uniquement si nécessaire.',
  max: 'Contrôle les invariants, les scènes et les régressions. Itère si la qualité visuelle ou la sécurité l’exige.',
});

const DIMENSIONS = ['task', 'agent', 'cycle', 'night'];
const DEFAULTS = {
  mode: 'eco',
  session: 'cycle',
  limits: { task: 24000, agent: 54000, cycle: 98000, night: 175000 },
  thresholds: { warn: .70, optimize: .85, reserve: .95 },
};

export function loadPolicy(root, overrides = {}) {
  const path = join(root, 'studio', 'token-policy.json');
  const config = existsSync(path) ? JSON.parse(readFileSync(path, 'utf8')) : {};
  const policy = {
    mode: overrides.mode ?? config.mode ?? DEFAULTS.mode,
    session: overrides.session ?? config.session ?? DEFAULTS.session,
    limits: { ...DEFAULTS.limits, ...config.limits, ...overrides.limits },
    thresholds: { ...DEFAULTS.thresholds, ...config.thresholds, ...overrides.thresholds },
  };
  if (!Object.hasOwn(MODES, policy.mode)) throw new Error('Mode de tokens invalide. Utiliser eco, normal ou max.');
  if (!['cycle', 'night'].includes(policy.session)) throw new Error('Session de tokens invalide.');
  for (const scope of DIMENSIONS) {
    const limit = policy.limits[scope];
    if (!Number.isSafeInteger(limit) || limit <= 0) throw new Error(`Budget invalide pour ${scope}.`);
  }
  const { warn, optimize, reserve } = policy.thresholds;
  if (!(0 < warn && warn < optimize && optimize < reserve && reserve < 1)) {
    throw new Error('Seuils invalides. Ils doivent être croissants et entre 0 et 1.');
  }
  return policy;
}

export function selectMode(policy, task) {
  if (task.priority === 'P0' || task.critical === true) return 'max';
  return Object.hasOwn(MODES, task.qualityMode) ? task.qualityMode : policy.mode;
}

export function readUsage(line) {
  let event;
  try {
    event = typeof line === 'string' ? JSON.parse(line) : line;
  } catch {
    return null;
  }
  const usage = event?.type === 'turn.completed' ? event.usage : null;
  if (!usage || !['input_tokens', 'output_tokens'].every(key =>
    Number.isSafeInteger(usage[key]) && usage[key] >= 0)) return null;
  const cached = usage.cached_input_tokens;
  return {
    input_tokens: usage.input_tokens,
    cached_input_tokens: Number.isSafeInteger(cached) && cached >= 0 && cached <= usage.input_tokens ? cached : null,
    output_tokens: usage.output_tokens,
  };
}

export function budgetDecision(policy, usage, task, mode = selectMode(policy, task)) {
  const scopes = policy.session === 'night' ? DIMENSIONS : DIMENSIONS.slice(0, 3);
  const ratios = scopes.flatMap(scope => {
    const used = usage?.[scope];
    const limit = scope === 'task' && Number.isSafeInteger(task.tokenBudget) && task.tokenBudget > 0
      ? Math.min(task.tokenBudget, policy.limits.task) : policy.limits[scope];
    return Number.isFinite(used) && used >= 0 ? [{ scope, ratio: used / limit }] : [];
  });
  const ratio = ratios.length ? Math.max(...ratios.map(item => item.ratio)) : null;
  const alerts = ratios.filter(item => item.ratio >= policy.thresholds.warn).map(item =>
    `${item.scope} ${Math.floor(item.ratio * 100)} % du budget mesuré`);
  const secondary = ['P2', 'P3', 'P4'].includes(task.priority) && task.critical !== true;
  const stop = ratio !== null && (ratio >= 1 || (ratio >= policy.thresholds.reserve && secondary));
  return { stop, alerts, optimize: mode !== 'max' && ratio !== null && ratio >= policy.thresholds.optimize, ratio };
}
