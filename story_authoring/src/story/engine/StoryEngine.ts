import { allParts, chapters } from "../chapters";
import type {
  Faction,
  Flag,
  GameEvent,
  Objective,
  Reward,
  StoryChapter,
  StoryPart,
} from "../types";

// ============================================================
//  StoryEngine — machine à états du récit (indépendante du moteur de rendu)
//  Le jeu envoie des GameEvent, le moteur avance et appelle des callbacks.
// ============================================================

export type Ending = "fin-veilleur" | "fin-chasseur" | "fin-liberation" | "inconnue";

export interface StoryCallbacks {
  onPartStart?: (part: StoryPart, chapter: StoryChapter) => void;
  onObjectiveProgress?: (part: StoryPart, index: number, progress: number, target: number) => void;
  onPartComplete?: (part: StoryPart) => void;
  onChapterComplete?: (chapter: StoryChapter) => void;
  onActComplete?: (act: number) => void;
  onReward?: (reward: Reward, part: StoryPart) => void;
  onChoiceRequired?: (partId: string, choiceId: string) => void;
  onFlag?: (flag: Flag) => void;
  onStoryEnd?: (ending: Ending) => void;
}

export interface StorySave {
  partIndex: number; // index global dans allParts
  progress: Record<string, number>;
  flags: Flag[];
  choices: Record<string, string>;
  reputation: Record<Faction, number>;
  lampPower: number;
  journal: string[];
}

const targetOf = (o: Objective): number => {
  switch (o.kind) {
    case "collect":
    case "defeat":
      return o.count;
    case "survive":
      return o.seconds;
    default:
      return 1;
  }
};

export class StoryEngine {
  private idx = 0;
  private progress: Record<string, number> = {};
  private flags = new Set<Flag>();
  private choices: Record<string, string> = {};
  private reputation: Record<Faction, number> = { "trois-vannes": 0, garde: 0, veilleurs: 0 };
  private lampPower = 0;
  private journal: string[] = [];
  private pendingChoices = new Set<string>();

  constructor(private cb: StoryCallbacks = {}) {}

  // ---------- Cycle de vie ----------
  start(): void {
    this.idx = 0;
    this.enter();
  }

  load(save: StorySave): void {
    this.idx = save.partIndex;
    this.progress = { ...save.progress };
    this.flags = new Set(save.flags);
    this.choices = { ...save.choices };
    this.reputation = { ...save.reputation };
    this.lampPower = save.lampPower;
    this.journal = [...save.journal];
    this.pendingChoices.clear();
    const p = this.currentPart();
    const chapter = this.currentChapter();
    if (p && chapter) {
      this.cb.onPartStart?.(p, chapter);
      p.choices?.forEach((c) => {
        if (!this.choices[c.id]) {
          this.pendingChoices.add(c.id);
          this.cb.onChoiceRequired?.(p.id, c.id);
        }
      });
    }
  }

  save(): StorySave {
    return {
      partIndex: this.idx,
      progress: { ...this.progress },
      flags: [...this.flags],
      choices: { ...this.choices },
      reputation: { ...this.reputation },
      lampPower: this.lampPower,
      journal: [...this.journal],
    };
  }

  // ---------- Lecture ----------
  currentPart(): StoryPart | undefined { return allParts[this.idx]; }
  currentChapter(): StoryChapter | undefined {
    const p = this.currentPart();
    return p ? chapters.find((c) => c.parts.includes(p)) : undefined;
  }
  hasFlag(flag: Flag): boolean { return this.flags.has(flag); }
  getLampPower(): number { return this.lampPower; }
  getReputation(): Record<Faction, number> { return { ...this.reputation }; }
  getJournal(): string[] { return [...this.journal]; }
  isFinished(): boolean { return this.idx >= allParts.length; }
  progressOf(objectiveIndex: number): number {
    const p = this.currentPart();
    return p ? this.progress[`${p.id}#${objectiveIndex}`] ?? 0 : 0;
  }

  // ---------- Événements envoyés par le jeu ----------
  emit(ev: GameEvent): void {
    const p = this.currentPart();
    if (!p || this.pendingChoices.size > 0) return;
    p.objectives.forEach((o, i) => {
      const key = `${p.id}#${i}`;
      const target = targetOf(o);
      const current = this.progress[key] ?? 0;
      if (current >= target) return;
      const inc = this.matches(o, ev);
      if (inc > 0) {
        const next = Math.min(target, current + inc);
        this.progress[key] = next;
        this.cb.onObjectiveProgress?.(p, i, next, target);
      }
    });
    this.checkPartComplete();
  }

  /** À appeler quand le joueur a fait un choix dans l'UI de dialogue. */
  choose(choiceId: string, optionId: string): void {
    const p = this.currentPart();
    const choice = p?.choices?.find((c) => c.id === choiceId);
    const option = choice?.options.find((o) => o.id === optionId);
    if (!p || !choice || !option) return;
    this.choices[choiceId] = optionId;
    option.setFlags?.forEach((f) => this.setFlag(f));
    this.addReputation(option.reputation);
    this.pendingChoices.delete(choiceId);
    this.checkPartComplete();
  }

  /** Debug / cinématiques : force la validation de la partie en cours. */
  skipPart(): void {
    const p = this.currentPart();
    if (!p) return;
    p.objectives.forEach((o, i) => { this.progress[`${p.id}#${i}`] = targetOf(o); });
    p.choices?.forEach((c) => {
      if (!this.choices[c.id] && c.options.length > 0) this.choose(c.id, c.options[0].id);
    });
    this.checkPartComplete();
  }

  // ---------- Interne ----------
  private matches(o: Objective, ev: GameEvent): number {
    switch (o.kind) {
      case "goto": return ev.type === "enter-zone" && ev.zone === o.zone ? 1 : 0;
      case "sneak": return ev.type === "sneaked" && ev.zone === o.zone ? 1 : 0;
      case "collect": return ev.type === "item-added" && ev.item === o.item ? ev.count : 0;
      case "talk": return ev.type === "npc-talked" && ev.npc === o.npc ? 1 : 0;
      case "interact": return ev.type === "interacted" && ev.target === o.target ? 1 : 0;
      case "craft": return ev.type === "crafted" && ev.item === o.item ? 1 : 0;
      case "build": return ev.type === "built" && ev.structure === o.structure ? 1 : 0;
      case "defeat": return ev.type === "enemy-defeated" && ev.enemy === o.enemy ? 1 : 0;
      case "survive": return ev.type === "survived" ? ev.seconds : 0;
      case "wait":
        return (ev.type === "tide" && ev.state === o.condition) || (ev.type === "time" && ev.period === o.condition) ? 1 : 0;
      case "deliver": return ev.type === "item-delivered" && ev.item === o.item && ev.npc === o.npc ? 1 : 0;
      case "solve": return ev.type === "puzzle-solved" && ev.puzzle === o.puzzle ? 1 : 0;
    }
  }

  private checkPartComplete(): void {
    const p = this.currentPart();
    if (!p) return;
    const objectivesDone = p.objectives.every(
      (o, i) => o.optional || (this.progress[`${p.id}#${i}`] ?? 0) >= targetOf(o),
    );
    const choicesDone = (p.choices ?? []).every((c) => this.choices[c.id]);
    if (objectivesDone && choicesDone) this.completePart(p);
  }

  private completePart(p: StoryPart): void {
    p.setFlags?.forEach((f) => this.setFlag(f));
    if (p.journalEntry) this.journal.push(p.journalEntry);
    if (p.rewards) this.applyReward(p.rewards, p);
    this.cb.onPartComplete?.(p);

    const chapter = this.currentChapter();
    const isLastOfChapter = chapter && chapter.parts[chapter.parts.length - 1] === p;
    if (isLastOfChapter && chapter) {
      this.cb.onChapterComplete?.(chapter);
      const next = chapters[chapters.indexOf(chapter) + 1];
      if (!next || next.act !== chapter.act) this.cb.onActComplete?.(chapter.act);
    }
    this.idx++;
    if (this.isFinished()) {
      const ending: Ending = this.flags.has("fin-veilleur") ? "fin-veilleur"
        : this.flags.has("fin-chasseur") ? "fin-chasseur"
        : this.flags.has("fin-liberation") ? "fin-liberation" : "inconnue";
      this.cb.onStoryEnd?.(ending);
      return;
    }
    this.enter();
  }

  private enter(): void {
    const p = this.currentPart();
    const chapter = this.currentChapter();
    if (!p || !chapter) return;
    // Partie conditionnée par un flag manquant : on la saute proprement.
    if (p.requireFlags && !p.requireFlags.every((f) => this.flags.has(f))) {
      this.idx++;
      if (!this.isFinished()) this.enter();
      return;
    }
    this.cb.onPartStart?.(p, chapter);
    p.choices?.forEach((c) => {
      if (!this.choices[c.id]) {
        this.pendingChoices.add(c.id);
        this.cb.onChoiceRequired?.(p.id, c.id);
      }
    });
  }

  private setFlag(f: Flag): void {
    if (this.flags.has(f)) return;
    this.flags.add(f);
    this.cb.onFlag?.(f);
  }

  private addReputation(r?: Partial<Record<Faction, number>>): void {
    if (!r) return;
    (Object.keys(r) as Faction[]).forEach((k) => {
      this.reputation[k] += r[k] ?? 0;
    });
  }

  private applyReward(r: Reward, p: StoryPart): void {
    if (r.lampPower !== undefined) this.lampPower = Math.max(this.lampPower, r.lampPower);
    this.addReputation(r.reputation);
    this.cb.onReward?.(r, p);
  }
}
