import type { StoryAct, StoryChapter, StoryPart } from "../types";
import { act1 } from "./act1";
import { act2 } from "./act2";
import { act3 } from "./act3";
import { act4 } from "./act4";
import { act5 } from "./act5";

export const acts: StoryAct[] = [
  {
    number: 1, title: "La Lampe Éteinte", setting: "Archipel de Keravel",
    synopsis: "La relève rallume le phare avec trois pièces retrouvées sur les îlots, mais la braise manque.",
  },
  {
    number: 2, title: "Trois-Vannes", setting: "Le grand village",
    synopsis: "Gagner la confiance du village, découvrir la légende de l'émeraude, démasquer le Baron et construire un bateau.",
  },
  {
    number: 3, title: "Enez-Aerouant", setting: "L'île extérieure",
    synopsis: "Naufrage sur l'île du dragon, rivière, forêt, marais, ruines : retrouver le dernier veilleur et apprendre la vérité.",
  },
  {
    number: 4, title: "La Citadelle de Kastell-Glas", setting: "Citadelle, mines et donjon",
    synopsis: "Infiltrer le camp, libérer les mineurs, affronter les gardes et le Baron, prendre le Kalon-Glas.",
  },
  {
    number: 5, title: "Le Dragon", setting: "De l'île au phare",
    synopsis: "Le dragon se réveille et attaque Trois-Vannes. Combat final au pied et au sommet du phare.",
  },
];

export const chapters: StoryChapter[] = [...act1, ...act2, ...act3, ...act4, ...act5];

export const allParts: StoryPart[] = chapters.flatMap((c) => c.parts);

export const chapterById = (id: string): StoryChapter | undefined => chapters.find((c) => c.id === id);
export const partById = (id: string): StoryPart | undefined => allParts.find((p) => p.id === id);

export { act1, act2, act3, act4, act5 };
