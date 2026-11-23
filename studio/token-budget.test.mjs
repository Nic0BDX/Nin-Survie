import assert from 'node:assert/strict';
import test from 'node:test';
import { fileURLToPath } from 'node:url';
import { budgetDecision, loadPolicy, readUsage, selectMode } from './token-budget.mjs';

const root = new URL('../', import.meta.url);
const policy = loadPolicy(fileURLToPath(root), {
  limits: { task: 100, agent: 100, cycle: 100, night: 100 },
  session: 'night',
});
const art = { priority: 'P2' };
const critical = { priority: 'P0' };

test('ÉCO par défaut et qualité maximale pour une tâche critique', () => {
  assert.equal(selectMode(policy, art), 'eco');
  assert.equal(selectMode(policy, critical), 'max');
});

test('seuils, réserve et plafond de distribution', () => {
  assert.equal(budgetDecision(policy, { cycle: 69 }, art).alerts.length, 0);
  assert.equal(budgetDecision(policy, { cycle: 70 }, art).alerts.length, 1);
  assert.equal(budgetDecision(policy, { cycle: 85 }, art).optimize, true);
  assert.equal(budgetDecision(policy, { cycle: 95 }, art).stop, true);
  assert.equal(budgetDecision(policy, { cycle: 95 }, critical).stop, false);
  assert.equal(budgetDecision(policy, { night: 100 }, critical).stop, true);
  assert.equal(budgetDecision(policy, { task: 48 }, { ...art, tokenBudget: 50 }).stop, true);
});

test('la télémétrie absente reste inconnue', () => {
  assert.equal(budgetDecision(policy, { task: null, cycle: null }, art).ratio, null);
  assert.equal(readUsage('pas un JSON'), null);
  assert.equal(readUsage({ type: 'turn.completed', usage: { output_tokens: 4 } }), null);
  assert.deepEqual(readUsage({
    type: 'turn.completed', usage: { input_tokens: 12, cached_input_tokens: 4, output_tokens: 7 },
  }), { input_tokens: 12, cached_input_tokens: 4, output_tokens: 7 });
});
