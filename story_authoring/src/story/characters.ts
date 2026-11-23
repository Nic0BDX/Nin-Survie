import type { Npc, NpcId } from "./types";

export const npcs: Record<NpcId, Npc> = {
  ewen: {
    id: "ewen", name: "Ewen Kerdreux", title: "Inspecteur du Service des feux", home: "tv-place-cloche",
    role: "Mentor par lettres. Envoie la relève à Keravel.",
    personality: "Sec, précis, chaleureux sous la rudesse. Signe toujours « Gardez la flamme ».",
  },
  goulven: {
    id: "goulven", name: "Goulven Mével", title: "Le Vieux Goulven", home: "le-courlis",
    role: "Marin rescapé du Courlis, plus tard capitaine du bateau.",
    personality: "Bourru, drôle, superstitieux. Parle à la mer comme à une vieille connaissance.",
  },
  soizic: {
    id: "soizic", name: "Soizic Penhoat", title: "Doyenne de Trois-Vannes", home: "tv-place-cloche",
    role: "Dirige le village, méfiante envers le Baron.",
    personality: "Ferme, juste, fatiguée. Protège les siens avant tout.",
  },
  tangi: {
    id: "tangi", name: "Tangi Le Roux", title: "Forgeron", home: "tv-forge",
    role: "Forge armes, armures et balistes.",
    personality: "Costaud, peu bavard, cœur d'or. Respecte ceux qui travaillent dur.",
  },
  nolwenn: {
    id: "nolwenn", name: "Nolwenn Abgrall", title: "Apothicaire", home: "tv-apothicaire",
    role: "Soins, antidotes, herbes rares.",
    personality: "Curieuse, malicieuse, parle en recettes.",
  },
  maelle: {
    id: "maelle", name: "Maëlle Quéré", title: "Cartographe", home: "tv-criee",
    role: "Dessine les cartes de l'archipel et de l'île extérieure.",
    personality: "Vive, ambitieuse, rêve de voir Enez-Aerouant.",
  },
  yannig: {
    id: "yannig", name: "Yannig", title: "Garçon d'auberge", home: "tv-auberge",
    role: "Guide du village, petit frère de cœur du joueur.",
    personality: "Malin, courageux, collectionne les coquillages brillants.",
  },
  corentin: {
    id: "corentin", name: "Corentin Madec", title: "Charpentier naval", home: "tv-chantier",
    role: "Construit le bateau de la traversée.",
    personality: "Perfectionniste, parle à ses planches.",
  },
  azenor: {
    id: "azenor", name: "Sœur Azenor", title: "Gardienne de la chapelle", home: "tv-chapelle",
    role: "Connaît la légende du dragon et de l'émeraude.",
    personality: "Douce, mystérieuse, humour pince-sans-rire.",
  },
  kerhoel: {
    id: "kerhoel", name: "Hoël de Kerhoël", title: "Baron de Trois-Vannes", home: "tv-manoir",
    role: "A volé le Kalon-Glas du phare pour sa fortune et son pouvoir.",
    personality: "Charmant, calculateur, convaincu d'agir pour le bien de tous.",
  },
  orwenn: {
    id: "orwenn", name: "Orwenn Le Bihan", title: "Capitaine de la Garde de l'Émeraude", home: "ea-citadelle-cour",
    role: "Chef des gardes, loyale par devoir, pas par conviction.",
    personality: "Droite, stoïque, hantée par ce qu'elle a laissé faire.",
  },
  ronan: {
    id: "ronan", name: "Ronan Guéguen", title: "Lieutenant de la Garde", home: "ea-camp-garde",
    role: "Garde qui change de camp et aide le joueur.",
    personality: "Jeune, honnête, mauvais menteur.",
  },
  erwan: {
    id: "erwan", name: "Erwan Le Bris", title: "Dernier veilleur de Keravel", home: "ea-ruines-veilleurs",
    role: "Ancien gardien du phare disparu, détient la clé de braise.",
    personality: "Épuisé, lucide, plein de remords.",
  },
  aerouant: {
    id: "aerouant", name: "Aerouant", title: "Le Dragon de Braise", home: "ea-antre-aerouant",
    role: "Dragon ancien scellé par le Kalon-Glas, antagoniste final.",
    personality: "Immense, patient, ironique. Parle lentement, comme la lave.",
  },
};
