// ============================================================
//  KERAVEL — Types du récit
//  Structure : Acte > Chapitre > Partie > (Objectifs, Dialogues, Choix, Combat)
// ============================================================

export type ZoneId = string;
export type ItemId = string;
export type EnemyId = string;
export type Flag = string;

export type NpcId =
  | "ewen"
  | "goulven"
  | "soizic"
  | "tangi"
  | "nolwenn"
  | "maelle"
  | "yannig"
  | "corentin"
  | "azenor"
  | "kerhoel"
  | "orwenn"
  | "ronan"
  | "erwan"
  | "aerouant";

export type Speaker = NpcId | "releve" | "narrateur";

export type Mood =
  | "neutre"
  | "joyeux"
  | "inquiet"
  | "colere"
  | "triste"
  | "mysterieux"
  | "solennel";

export type Faction = "trois-vannes" | "garde" | "veilleurs";

export interface DialogueLine {
  speaker: Speaker;
  text: string;
  mood?: Mood;
}

// ---------- Objectifs ----------
export type Objective = { label: string; optional?: boolean } & (
  | { kind: "goto"; zone: ZoneId }
  | { kind: "collect"; item: ItemId; count: number }
  | { kind: "talk"; npc: NpcId }
  | { kind: "interact"; target: string }
  | { kind: "craft"; item: ItemId }
  | { kind: "build"; structure: string }
  | { kind: "defeat"; enemy: EnemyId; count: number }
  | { kind: "survive"; seconds: number }
  | { kind: "wait"; condition: "maree-basse" | "maree-haute" | "nuit" | "jour" }
  | { kind: "sneak"; zone: ZoneId }
  | { kind: "deliver"; item: ItemId; npc: NpcId }
  | { kind: "solve"; puzzle: string }
);

// ---------- Récompenses ----------
export interface Reward {
  items?: { item: ItemId; count: number }[];
  /** Puissance de la lampe du phare (0-100). 35 = braise de fortune, 100 = Kalon-Glas. */
  lampPower?: number;
  reputation?: Partial<Record<Faction, number>>;
  unlockZones?: ZoneId[];
  unlockRecipes?: string[];
  unlockAbilities?: string[];
}

// ---------- Choix ----------
export interface ChoiceOption {
  id: string;
  label: string;
  setFlags?: Flag[];
  reputation?: Partial<Record<Faction, number>>;
  consequence?: string;
}
export interface Choice {
  id: string;
  prompt: string;
  options: ChoiceOption[];
}

// ---------- Combat ----------
export interface CombatEncounter {
  id: string;
  arena: ZoneId;
  enemies: { enemy: EnemyId; count: number }[];
  boss?: EnemyId;
  rules?: string[];
}

// ---------- Partie / Chapitre / Acte ----------
export interface StoryPart {
  id: string; // ex: "c01-p1"
  title: string;
  zone: ZoneId;
  summary: string;
  objectives: Objective[];
  dialogue: DialogueLine[];
  /** Description caméra / mise en scène (pour cinématique ou scène scriptée) */
  cinematic?: string;
  journalEntry?: string;
  choices?: Choice[];
  combat?: CombatEncounter;
  requireFlags?: Flag[];
  setFlags?: Flag[];
  rewards?: Reward;
}

export interface StoryChapter {
  id: string; // ex: "c01"
  number: number;
  act: 1 | 2 | 3 | 4 | 5;
  title: string;
  synopsis: string;
  parts: StoryPart[];
}

export interface StoryAct {
  number: 1 | 2 | 3 | 4 | 5;
  title: string;
  setting: string;
  synopsis: string;
}

// ---------- Monde ----------
export type Region = "archipel" | "trois-vannes" | "enez-aerouant";

export interface Zone {
  id: ZoneId;
  name: string;
  region: Region;
  biome: string;
  description: string;
  links: ZoneId[];
  /** Si défini : accès conditionné (marée basse = passe, bateau, clé…) */
  access?: "libre" | "maree-basse" | "bateau" | "pont" | "gue" | "cle";
  points?: string[];
}

export interface River {
  id: string;
  name: string;
  source: ZoneId;
  mouth: ZoneId;
  course: ZoneId[];
  crossings: { zone: ZoneId; kind: "gue" | "pont-de-corde" | "barque" | "cascade" }[];
}

export interface Npc {
  id: NpcId;
  name: string;
  title: string;
  home: ZoneId;
  role: string;
  personality: string;
}

export interface Item {
  id: ItemId;
  name: string;
  kind: "ressource" | "outil" | "arme" | "soin" | "cle" | "quete";
  description: string;
}

export interface Recipe {
  id: string;
  output: ItemId;
  needs: { item: ItemId; count: number }[];
  station?: string;
}

export interface BossPhase {
  id: string;
  name: string;
  hpThreshold: number; // % de PV à partir duquel la phase commence
  arena: ZoneId;
  attacks: { name: string; telegraph: string; counter: string }[];
  mechanic: string;
}

export interface Enemy {
  id: EnemyId;
  name: string;
  tier: "commun" | "elite" | "mini-boss" | "boss";
  hp: number;
  damage: number;
  behavior: string;
  weakness?: string;
  phases?: BossPhase[];
}

// ---------- Événements envoyés par le jeu au moteur ----------
export type GameEvent =
  | { type: "enter-zone"; zone: ZoneId }
  | { type: "sneaked"; zone: ZoneId }
  | { type: "item-added"; item: ItemId; count: number }
  | { type: "npc-talked"; npc: NpcId }
  | { type: "interacted"; target: string }
  | { type: "crafted"; item: ItemId }
  | { type: "built"; structure: string }
  | { type: "enemy-defeated"; enemy: EnemyId }
  | { type: "survived"; seconds: number }
  | { type: "tide"; state: "maree-basse" | "maree-haute" }
  | { type: "time"; period: "nuit" | "jour" }
  | { type: "item-delivered"; item: ItemId; npc: NpcId }
  | { type: "puzzle-solved"; puzzle: string };
