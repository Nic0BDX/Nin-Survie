import type {
  DialogueLine,
  Mood,
  NpcId,
  Objective,
  Speaker,
  StoryChapter,
  StoryPart,
} from "./types";

// ---------- Dialogue ----------
export const say = (speaker: Speaker, text: string, mood?: Mood): DialogueLine => ({
  speaker,
  text,
  ...(mood ? { mood } : {}),
});

// ---------- Objectifs ----------
export const goTo = (zone: string, label: string, optional = false): Objective => ({
  kind: "goto", zone, label, optional,
});
export const collect = (item: string, count: number, label: string): Objective => ({
  kind: "collect", item, count, label,
});
export const talk = (npc: NpcId, label: string): Objective => ({
  kind: "talk", npc, label,
});
export const interact = (target: string, label: string): Objective => ({
  kind: "interact", target, label,
});
export const craft = (item: string, label: string): Objective => ({
  kind: "craft", item, label,
});
export const build = (structure: string, label: string): Objective => ({
  kind: "build", structure, label,
});
export const defeat = (enemy: string, count: number, label: string): Objective => ({
  kind: "defeat", enemy, count, label,
});
export const survive = (seconds: number, label: string): Objective => ({
  kind: "survive", seconds, label,
});
export const waitFor = (
  condition: "maree-basse" | "maree-haute" | "nuit" | "jour",
  label: string,
): Objective => ({ kind: "wait", condition, label });
export const sneak = (zone: string, label: string): Objective => ({
  kind: "sneak", zone, label,
});
export const deliver = (item: string, npc: NpcId, label: string): Objective => ({
  kind: "deliver", item, npc, label,
});
export const solve = (puzzle: string, label: string): Objective => ({
  kind: "solve", puzzle, label,
});

// ---------- Constructeurs ----------
export const part = (p: StoryPart): StoryPart => p;
export const chapter = (c: StoryChapter): StoryChapter => c;
