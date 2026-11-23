import type { Enemy, Item, Recipe } from "./types";

// ============================================================
//  OBJETS
// ============================================================
export const items: Item[] = [
  // Ressources (déjà présentes dans le HUD de la base)
  { id: "bois", name: "Bois", kind: "ressource", description: "Rondins et branches ramassés au sol." },
  { id: "silex", name: "Silex", kind: "ressource", description: "Éclats tranchants, pour le feu et les outils." },
  { id: "rations", name: "Rations", kind: "soin", description: "Nourriture qui apaise la Faim." },
  { id: "baies", name: "Baies", kind: "soin", description: "Baies rouges des buissons côtiers." },
  { id: "sel", name: "Sel gris", kind: "ressource", description: "Sel des marais salants, conserve les rations." },
  { id: "fer", name: "Fer", kind: "ressource", description: "Lingot brut pour la forge de Tangi." },
  { id: "planche", name: "Planche", kind: "ressource", description: "Planche rabotée pour la coque du bateau." },
  { id: "toile", name: "Toile de voile", kind: "ressource", description: "Toile épaisse cousue au village." },
  { id: "herbe-marais", name: "Herbe de marais", kind: "ressource", description: "Base de l'antidote de Nolwenn." },
  { id: "poussiere-emeraude", name: "Poussière d'émeraude", kind: "ressource", description: "Poudre verte extraite des Mines Vertes." },
  // Pièces du phare
  { id: "lentille", name: "Lentille du Courlis", kind: "quete", description: "Lentille de Fresnel retrouvée dans la cale." },
  { id: "reflecteur", name: "Réflecteur de la Corne", kind: "quete", description: "Réflecteur de cuivre sous le treuil." },
  { id: "dynamo", name: "Dynamo des Salines", kind: "quete", description: "Dynamo de l'atelier, remise en état." },
  { id: "braise-fortune", name: "Braise de fortune", kind: "quete", description: "Braise ordinaire. Éclaire faiblement le phare." },
  { id: "kalon-glas", name: "Le Kalon-Glas", kind: "quete", description: "L'Émeraude-Cœur de Keravel. Contient la lumière qui endort le dragon." },
  // Outils & armes
  { id: "lanterne", name: "Lanterne", kind: "outil", description: "Éclaire la nuit et la brume." },
  { id: "hache", name: "Hache de bûcheron", kind: "outil", description: "Coupe le bois, pare un coup." },
  { id: "pioche", name: "Pioche", kind: "outil", description: "Casse le silex et les éboulis." },
  { id: "boussole", name: "Boussole du Service", kind: "outil", description: "Suit un site choisi sur la carte." },
  { id: "carte-enez", name: "Carte d'Enez-Aerouant", kind: "cle", description: "Carte de Maëlle de l'île extérieure." },
  { id: "epee-fer", name: "Épée de fer", kind: "arme", description: "Forgée par Tangi." },
  { id: "bouclier", name: "Bouclier de pont", kind: "arme", description: "Bouclier en planches cerclées de fer." },
  { id: "arbalete", name: "Arbalète", kind: "arme", description: "Tir à distance, précis, lent à recharger." },
  { id: "harpon", name: "Harpon de baleinier", kind: "arme", description: "Se lance sur la mer, retenu par une corde." },
  { id: "antidote", name: "Antidote du Stank", kind: "soin", description: "Soigne le poison du marais." },
  { id: "uniforme-garde", name: "Uniforme de la Garde", kind: "cle", description: "Permet de passer pour un garde, brièvement." },
  { id: "cle-braise", name: "Clé de braise", kind: "cle", description: "Ouvre la Salle Verte du donjon." },
  { id: "cle-caves", name: "Clé des caves", kind: "cle", description: "Ouvre la trappe sous la chapelle." },
  { id: "boite-veilleur", name: "Boîte des veilleurs", kind: "quete", description: "Boîte cachée contenant un souvenir des premiers Veilleurs (3 à trouver)." },
];

export const recipes: Recipe[] = [
  { id: "r-feu", output: "braise-fortune", needs: [{ item: "bois", count: 3 }, { item: "silex", count: 1 }] },
  { id: "r-hache", output: "hache", needs: [{ item: "bois", count: 2 }, { item: "silex", count: 2 }], station: "etabli" },
  { id: "r-pioche", output: "pioche", needs: [{ item: "bois", count: 2 }, { item: "silex", count: 3 }], station: "etabli" },
  { id: "r-epee", output: "epee-fer", needs: [{ item: "fer", count: 3 }, { item: "bois", count: 1 }], station: "forge-tangi" },
  { id: "r-bouclier", output: "bouclier", needs: [{ item: "planche", count: 2 }, { item: "fer", count: 1 }], station: "forge-tangi" },
  { id: "r-arbalete", output: "arbalete", needs: [{ item: "fer", count: 2 }, { item: "bois", count: 3 }], station: "forge-tangi" },
  { id: "r-harpon", output: "harpon", needs: [{ item: "fer", count: 2 }, { item: "bois", count: 2 }], station: "forge-tangi" },
  { id: "r-antidote", output: "antidote", needs: [{ item: "herbe-marais", count: 3 }, { item: "sel", count: 1 }], station: "apothicairerie" },
  { id: "r-rations", output: "rations", needs: [{ item: "baies", count: 3 }, { item: "sel", count: 1 }] },
];

// ============================================================
//  ENNEMIS
// ============================================================
export const enemies: Enemy[] = [
  { id: "goeland-pillard", name: "Goéland pillard", tier: "commun", hp: 15, damage: 3, behavior: "Pique les rations au joueur puis s'enfuit." },
  { id: "crabe-geant", name: "Crabe des récifs", tier: "commun", hp: 40, damage: 6, behavior: "Attaque latérale, bloque les passes de marée.", weakness: "ventre (coup par derrière)" },
  { id: "spectre-brume", name: "Spectre de brume", tier: "commun", hp: 30, damage: 8, behavior: "Apparaît dans la brume, disparaît à la lumière.", weakness: "lanterne / lumière du phare" },
  { id: "loup-des-landes", name: "Loup des landes", tier: "commun", hp: 35, damage: 7, behavior: "Chasse en meute de 3." },
  { id: "garde-recrue", name: "Garde recrue", tier: "commun", hp: 45, damage: 7, behavior: "Patrouille, épée courte, appelle du renfort." },
  { id: "garde-lance", name: "Garde lancier", tier: "commun", hp: 55, damage: 10, behavior: "Allonge longue, charge en ligne.", weakness: "flancs" },
  { id: "garde-arbalete", name: "Garde arbalétrier", tier: "commun", hp: 35, damage: 12, behavior: "Tire de loin depuis les remparts." },
  { id: "garde-bouclier", name: "Garde de bouclier", tier: "elite", hp: 90, damage: 9, behavior: "Bloque l'avant, assomme sur contre.", weakness: "dos et attaques chargées" },
  { id: "cerf-de-brume", name: "Le Cerf de Brume", tier: "mini-boss", hp: 220, damage: 14, behavior: "Gardien de la forêt, appelle des feux follets, charge avec ses bois.", weakness: "lumière vive (lanterne)" },
  { id: "serpent-de-stank", name: "Le Serpent de Stank", tier: "mini-boss", hp: 280, damage: 16, behavior: "Surgit de la vase, poison, étreinte.", weakness: "tête quand il sort de l'eau" },
  { id: "golem-de-schiste", name: "Golem de schiste", tier: "mini-boss", hp: 320, damage: 18, behavior: "Lent, écrase au sol, se régénère près du rocher.", weakness: "noyau lumineux dans le dos" },
  { id: "maitre-darmes", name: "Maître d'armes Kervella", tier: "boss", hp: 450, damage: 20, behavior: "Duel rapide, enchaînements à 3 coups, parades parfaites." },
  { id: "capitaine-orwenn", name: "Capitaine Orwenn", tier: "boss", hp: 600, damage: 22, behavior: "Épée et bouclier, change de style à mi-vie. Peut être épargnée." },
  { id: "baron-kerhoel", name: "Baron Hoël de Kerhoël", tier: "boss", hp: 700, damage: 24, behavior: "Duelliste armé d'un éclat d'émeraude, tire des rayons verts, fuit quand il perd." },
  {
    id: "aerouant", name: "Aerouant, le Dragon de Braise", tier: "boss", hp: 4000, damage: 45,
    behavior: "Dragon colossal, vole, souffle de braise, queue, écrasement.",
    weakness: "Le faisceau vert du Kalon-Glas, ventre sans écailles",
    phases: [
      {
        id: "dragon-p1-ciel", name: "Le Ciel de Feu", hpThreshold: 100, arena: "tv-port",
        attacks: [
          { name: "Passage en rase-mottes", telegraph: "Ombre géante qui grandit au sol", counter: "Se mettre à couvert derrière les maisons" },
          { name: "Pluie de braises", telegraph: "Le dragon gonfle sa gorge en haut", counter: "Sprinter hors des cercles rouges" },
        ],
        mechanic: "Charger les balistes de Tangi avec Yannig et les villageois, viser les ailes pour le faire atterrir.",
      },
      {
        id: "dragon-p2-sol", name: "Le Dragon au Sol", hpThreshold: 70, arena: "prairie-phare",
        attacks: [
          { name: "Coup de queue", telegraph: "Il pivote lentement", counter: "Sauter ou rouler vers l'arrière" },
          { name: "Morsure", telegraph: "Il recule la tête", counter: "Esquiver sur le côté puis frapper la gueule" },
          { name: "Souffle de braise en cône", telegraph: "Lueur orange dans la gorge", counter: "Se cacher derrière un menhir ou la barrière en pierre" },
        ],
        mechanic: "Frapper le ventre exposé après chaque souffle pour des dégâts critiques.",
      },
      {
        id: "dragon-p3-lumiere", name: "La Lumière Verte", hpThreshold: 40, arena: "phare-keravel",
        attacks: [
          { name: "Rugissement de brume", telegraph: "Brume épaisse qui monte", counter: "Garder la lanterne allumée pour voir les spectres" },
          { name: "Colonne de feu", telegraph: "Fissure rouge dans le sol", counter: "Rester en mouvement dans la tour" },
        ],
        mechanic: "Insérer le Kalon-Glas dans la lampe puis orienter le faisceau vert sur le dragon pour l'étourdir.",
      },
      {
        id: "dragon-p4-agonie", name: "L'Agonie de Braise", hpThreshold: 15, arena: "phare-keravel",
        attacks: [
          { name: "Tempête de feu", telegraph: "Il monte en spirale", counter: "Se plaquer contre la lanterne protégée" },
          { name: "Dernier souffle", telegraph: "Compte à rebours de 5 s", counter: "Faisceau plein pouvoir au bon moment" },
        ],
        mechanic: "Séquence de timing : maintenir le faisceau pendant que la marée de braise recule. Fin au choix du joueur.",
      },
    ],
  },
];
