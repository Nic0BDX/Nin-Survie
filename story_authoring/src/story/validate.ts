import { allParts, chapters, acts } from "./chapters";
import { enemies, items, recipes } from "./database";
import { npcs } from "./characters";
import { zones, rivers } from "./world";
import { StoryEngine } from "./engine/StoryEngine";

// Lancer : npx tsx src/story/validate.ts   (ou compiler puis node)
declare const process: { exitCode?: number };

export function validateStory(): string[] {
  const errors: string[] = [];
  const zoneIds = new Set(zones.map((z) => z.id));
  const itemIds = new Set(items.map((i) => i.id));
  const enemyIds = new Set(enemies.map((e) => e.id));
  const npcIds = new Set(Object.keys(npcs));

  // --- IDs uniques ---
  const seen = new Set<string>();
  for (const p of allParts) {
    if (seen.has(p.id)) errors.push(`ID de partie en double : ${p.id}`);
    seen.add(p.id);
  }

  // --- Monde ---
  for (const z of zones) {
    for (const l of z.links) if (!zoneIds.has(l)) errors.push(`Zone ${z.id} : lien inconnu ${l}`);
  }
  for (const r of rivers) {
    for (const z of r.course) if (!zoneIds.has(z)) errors.push(`Rivière ${r.id} : zone inconnue ${z}`);
  }
  for (const n of Object.values(npcs)) {
    if (!zoneIds.has(n.home)) errors.push(`PNJ ${n.id} : home inconnu ${n.home}`);
  }
  for (const r of recipes) {
    if (!itemIds.has(r.output)) errors.push(`Recette ${r.id} : sortie inconnue ${r.output}`);
    for (const n of r.needs) if (!itemIds.has(n.item)) errors.push(`Recette ${r.id} : ingrédient inconnu ${n.item}`);
  }

  // --- Chapitres / parties ---
  for (const c of chapters) {
    if (c.parts.length < 3) errors.push(`Chapitre ${c.id} : moins de 3 parties`);
    for (const p of c.parts) {
      if (!zoneIds.has(p.zone)) errors.push(`${p.id} : zone inconnue ${p.zone}`);
      if (p.objectives.length === 0) errors.push(`${p.id} : aucun objectif`);
      if (p.dialogue.length === 0) errors.push(`${p.id} : aucun dialogue`);
      for (const d of p.dialogue) {
        if (d.speaker !== "releve" && d.speaker !== "narrateur" && !npcIds.has(d.speaker))
          errors.push(`${p.id} : locuteur inconnu ${d.speaker}`);
      }
      for (const o of p.objectives) {
        if ((o.kind === "goto" || o.kind === "sneak") && !zoneIds.has(o.zone)) errors.push(`${p.id} : objectif zone inconnue ${o.zone}`);
        if ((o.kind === "collect" || o.kind === "craft" || o.kind === "deliver") && !itemIds.has(o.item)) errors.push(`${p.id} : objectif objet inconnu ${o.item}`);
        if (o.kind === "defeat" && !enemyIds.has(o.enemy)) errors.push(`${p.id} : objectif ennemi inconnu ${o.enemy}`);
        if ((o.kind === "talk" || o.kind === "deliver") && !npcIds.has(o.npc)) errors.push(`${p.id} : objectif PNJ inconnu ${o.npc}`);
      }
      for (const r of p.rewards?.items ?? []) if (!itemIds.has(r.item)) errors.push(`${p.id} : récompense objet inconnu ${r.item}`);
      for (const z of p.rewards?.unlockZones ?? []) if (!zoneIds.has(z)) errors.push(`${p.id} : unlockZone inconnue ${z}`);
      for (const rid of p.rewards?.unlockRecipes ?? []) if (!recipes.some((r) => r.id === rid)) errors.push(`${p.id} : recette inconnue ${rid}`);
      if (p.combat) {
        if (!zoneIds.has(p.combat.arena)) errors.push(`${p.id} : arène inconnue ${p.combat.arena}`);
        for (const e of p.combat.enemies) if (!enemyIds.has(e.enemy)) errors.push(`${p.id} : ennemi de combat inconnu ${e.enemy}`);
      }
    }
  }

  // --- Flags requis jamais posés ---
  const setFlags = new Set<string>();
  allParts.forEach((p) => {
    p.setFlags?.forEach((f) => setFlags.add(f));
    p.choices?.forEach((c) => c.options.forEach((o) => o.setFlags?.forEach((f) => setFlags.add(f))));
  });
  for (const p of allParts) for (const f of p.requireFlags ?? []) if (!setFlags.has(f)) errors.push(`${p.id} : flag requis jamais posé ${f}`);

  return errors;
}

/** Simule toute l'histoire en forçant chaque partie, avec un choix de fin donné. */
export function simulate(endingOptionId: "sceller" | "tuer" | "liberer"): { ending: string; parts: number } {
  let ending = "non terminée";
  let completed = 0;
  const engine = new StoryEngine({
    onPartComplete: () => { completed++; },
    onChoiceRequired: (_pid, cid) => {
      if (cid === "fin-dragon") queueMicrotask(() => engine.choose(cid, endingOptionId));
    },
    onStoryEnd: (e) => { ending = e; },
  });
  engine.start();
  let guard = 0;
  while (!engine.isFinished() && guard++ < 500) {
    const p = engine.currentPart();
    if (p?.choices?.some((c) => c.id === "fin-dragon") && !engine.hasFlag("fin-veilleur") && !engine.hasFlag("fin-chasseur") && !engine.hasFlag("fin-liberation")) {
      engine.choose("fin-dragon", endingOptionId);
    }
    engine.skipPart();
  }
  return { ending, parts: completed };
}

// ---------- Exécution directe ----------
const errs = validateStory();
console.log(`Actes : ${acts.length} · Chapitres : ${chapters.length} · Parties : ${allParts.length} · Zones : ${zones.length}`);
console.log(`Dialogues : ${allParts.reduce((n, p) => n + p.dialogue.length, 0)} répliques · Objectifs : ${allParts.reduce((n, p) => n + p.objectives.length, 0)}`);
if (errs.length) {
  console.error(`\n${errs.length} erreur(s) :`);
  errs.forEach((e) => console.error(" - " + e));
  process.exitCode = 1;
} else {
  console.log("Validation OK : toutes les références sont cohérentes.");
}
for (const opt of ["sceller", "tuer", "liberer"] as const) {
  const r = simulate(opt);
  console.log(`Simulation (${opt}) → fin : ${r.ending}, parties jouées : ${r.parts}`);
}
