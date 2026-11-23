import { readFileSync, statSync } from 'node:fs';
import { dirname, isAbsolute, relative, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const catalogPath = fileURLToPath(new URL('./catalog.json', import.meta.url));
const project = resolve(dirname(catalogPath), '../..');
const catalog = JSON.parse(readFileSync(catalogPath, 'utf8'));
const story = JSON.parse(readFileSync(resolve(project, 'keravel_story.json'), 'utf8'));
const issues = [];
const mandatory = [
  'geometry', 'silhouette', 'facade', 'roof', 'openings', 'materials',
  'interior', 'furniture', 'lighting', 'collisions', 'environment', 'performance',
];
const zones = new Set(story.zones.map(zone => zone.id));
const seenFamilies = new Map();
const seenBuildings = new Set();
const isText = value => typeof value === 'string' && value.trim().length > 0;

function issue(condition, message) {
  if (!condition) issues.push(message);
}

function projectFile(name) {
  if (!isText(name) || isAbsolute(name)) return undefined;
  const target = resolve(project, name);
  const relation = relative(project, target);
  if (relation === '' || isAbsolute(relation) || relation.split(/[\\/]/)[0] === '..') return undefined;
  try {
    return statSync(target).isFile() ? target : undefined;
  } catch {
    return undefined;
  }
}

issue(catalog.version === 1, 'Version de catalogue inconnue.');
issue(Object.keys(catalog.criteria).length === mandatory.length
  && mandatory.every(criterion => isText(catalog.criteria[criterion])), 'Il faut les douze critères documentés.');

for (const family of catalog.families) {
  issue(isText(family.id) && !seenFamilies.has(family.id), `Identifiant de famille absent ou dupliqué ${family.id}.`);
  seenFamilies.set(family.id, family);
  issue(isText(family.label) && family.variants.length > 0 && family.variants.every(isText),
    `${family.id} doit définir ses variantes.`);
  const source = projectFile(family.builder?.file);
  const symbol = family.builder?.symbol ?? '';
  issue(source && /^[a-z_][a-z0-9_]*$/i.test(symbol)
    && new RegExp(`^\\s*(?:static\\s+)?func\\s+${symbol}\\s*\\(`, 'm').test(readFileSync(source, 'utf8')),
  `Constructeur absent pour ${family.id}.`);
  const ids = new Set(family.detailLevels.map(level => level.id));
  issue(ids.size === family.detailLevels.length && ids.size > 0, `Niveaux de détail manquants ou dupliqués pour ${family.id}.`);
  for (const level of family.detailLevels) {
    issue(isText(level.id) && ['source', 'todo'].includes(level.status) && isText(level.selection)
      && level.features.length > 0 && level.features.every(isText), `Niveau de détail incomplet pour ${family.id}.`);
  }
  for (const [criterion, evidence] of Object.entries(family.observed ?? {})) {
    issue(mandatory.includes(criterion) && isText(evidence), `Observation invalide pour ${family.id} / ${criterion}.`);
  }
}

const report = [];
for (const building of catalog.buildings) {
  const { id, name, zone, family, essential, exemptions = {} } = building;
  issue(isText(id) && !seenBuildings.has(id) && isText(name), `Bâtiment absent ou dupliqué ${id}.`);
  seenBuildings.add(id);
  issue(zones.has(zone), `${id} pointe vers une zone absente du récit.`);
  issue(seenFamilies.has(family), `${id} pointe vers une famille inconnue.`);
  issue(essential.length > 0 && essential.every(criterion => mandatory.includes(criterion)),
    `Critères essentiels invalides pour ${id}.`);
  for (const [criterion, reason] of Object.entries(exemptions)) {
    issue(mandatory.includes(criterion) && !essential.includes(criterion) && isText(reason),
      `Exemption invalide pour ${id} / ${criterion}.`);
  }
  const review = catalog.reviews[id] ?? {};
  const missing = [];
  const failed = [];
  for (const [criterion, result] of Object.entries(review)) {
    issue(mandatory.includes(criterion) && !Object.hasOwn(exemptions, criterion)
      && ['pass', 'fail'].includes(result.status) && isText(result.note)
      && isText(result.reviewer) && /^\d{4}-\d{2}-\d{2}$/.test(result.date ?? '')
      && projectFile(result.evidence), `Preuve de revue invalide pour ${id} / ${criterion}.`);
  }
  for (const criterion of mandatory) {
    if (Object.hasOwn(exemptions, criterion)) continue;
    if (review[criterion]?.status === 'fail') failed.push(criterion);
    if (!review[criterion]) missing.push(criterion);
  }
  report.push({ id, name, zone, family, approved: missing.length === 0 && failed.length === 0,
    missing, failed, essentialOpen: essential.filter(criterion => review[criterion]?.status !== 'pass') });
}

for (const id of Object.keys(catalog.reviews)) issue(seenBuildings.has(id), `Revue orpheline ${id}.`);
const args = process.argv.slice(2);
const gates = args.filter(arg => arg.startsWith('--gate='));
for (const arg of args) issue(arg === '--json' || arg.startsWith('--gate='), `Option inconnue ${arg}.`);
for (const gate of gates) issue(report.some(item => item.id === gate.slice(7)), `Bâtiment inconnu pour ${gate}.`);
const blocked = report.filter(item => gates.includes(`--gate=${item.id}`) && !item.approved);

if (args.includes('--json')) {
  console.log(JSON.stringify({ valid: issues.length === 0, issues, buildings: report, blocked }, null, 2));
} else {
  for (const error of issues) console.error(error);
  console.log(`${catalog.families.length} familles, ${report.length} bâtiments, ${report.filter(item => item.approved).length} validés.`);
  for (const item of report) {
    console.log(`${item.id} — ${item.approved ? 'validé' : `${item.missing.length} à vérifier, ${item.failed.length} en échec`}`);
  }
  for (const item of blocked) console.error(`Validation refusée pour ${item.id}.`);
}
process.exitCode = issues.length ? 2 : (blocked.length ? 1 : 0);
