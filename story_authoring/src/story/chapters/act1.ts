import { build, chapter, collect, craft, defeat, goTo, interact, part, say, solve, survive, talk, waitFor } from "../helpers";

// ============================================================
//  ACTE I — LA LAMPE ÉTEINTE   (archipel de Keravel)
//  Chapitres 1 à 6 · 18 parties
// ============================================================

export const act1 = [
  // ---------------------------------------------------------- CH 1
  chapter({
    id: "c01", number: 1, act: 1, title: "L'Arrivée sur Keravel",
    synopsis: "La relève du Service des feux débarque sur un archipel où la cloche du phare résonne encore, mais où la lampe est morte.",
    parts: [
      part({
        id: "c01-p1", title: "Le ponton et la cloche", zone: "ponton-arrivee",
        summary: "Le bateau repart. La relève reste seule sur le ponton, la cloche sonne dans la brume.",
        cinematic: "Plan large sur la mer, mouettes, cloche en off. Caméra qui monte vers la prairie et le phare rouge et blanc.",
        objectives: [interact("cloche-lointaine", "Écouter la cloche"), goTo("prairie-phare", "Rejoindre la prairie")],
        dialogue: [
          say("narrateur", "La cloche résonne encore.", "mysterieux"),
          say("releve", "Quelqu'un sonne. Donc quelqu'un vit ici.", "inquiet"),
          say("ewen", "(Lettre) Arrivée confirmée. Le phare de Keravel est éteint depuis trois ans. Rallumez-le. Gardez la flamme.", "solennel"),
        ],
        journalEntry: "Journal de relève — Jour 1. Débarqué à Keravel. Le phare est muet, la cloche, elle, sonne toujours.",
      }),
      part({
        id: "c01-p2", title: "Premiers gestes", zone: "prairie-phare",
        summary: "Tutoriel de survie : ramasser, cueillir, lire le HUD (Vie, Chaleur, Faim).",
        objectives: [collect("bois", 5, "Ramasser 5 bois"), collect("baies", 3, "Cueillir 3 baies"), collect("silex", 2, "Trouver 2 silex")],
        dialogue: [
          say("narrateur", "[E] Ramasser le bois — [E] Cueillir les baies.", "neutre"),
          say("releve", "Un feu, de quoi manger, et on verra pour le reste.", "neutre"),
        ],
        rewards: { unlockRecipes: ["r-feu", "r-rations"] },
      }),
      part({
        id: "c01-p3", title: "Le feu de camp", zone: "prairie-phare",
        summary: "Première nuit : on allume un feu pour garder la Chaleur.",
        objectives: [craft("braise-fortune", "Allumer un feu"), waitFor("nuit", "Passer le crépuscule près du feu"), survive(45, "Tenir 45 secondes au chaud")],
        dialogue: [
          say("narrateur", "Le vent tombe. La Chaleur baisse vite quand le soleil se couche.", "neutre"),
          say("releve", "Allez, petite flamme. Tiens-moi compagnie.", "joyeux"),
        ],
        setFlags: ["premiere-nuit"],
      }),
    ],
  }),

  // ---------------------------------------------------------- CH 2
  chapter({
    id: "c02", number: 2, act: 1, title: "Le Phare Muet",
    synopsis: "Le phare est ouvert, abandonné, et un journal de veilleur raconte ce qui manque.",
    parts: [
      part({
        id: "c02-p1", title: "Devant la porte rouge", zone: "phare-keravel",
        summary: "La porte du phare cède après quelques coups. L'intérieur sent le sel et la cendre froide.",
        objectives: [goTo("phare-keravel", "Entrer dans le phare"), interact("porte-phare", "Forcer la porte")],
        dialogue: [
          say("releve", "Personne depuis trois ans. Et pourtant la cloche…", "inquiet"),
          say("narrateur", "La poussière a recouvert l'escalier, sauf quelques marches. Récentes.", "mysterieux"),
        ],
      }),
      part({
        id: "c02-p2", title: "Le journal du veilleur", zone: "phare-keravel",
        summary: "Dans la salle du journal : le carnet d'Erwan Le Bris et l'inventaire des pièces manquantes.",
        objectives: [interact("journal-erwan", "Lire le journal d'Erwan")],
        dialogue: [
          say("erwan", "(Journal) Pièces 0/3. Il manque la lentille, le réflecteur, la dynamo. Et la braise. La braise n'est plus dans la lanterne.", "triste"),
          say("erwan", "(Journal) Quelqu'un est venu de nuit. Je n'ai vu que des bottes vertes.", "inquiet"),
          say("releve", "Une braise, trois pièces, et un voleur. Commençons par le plus simple.", "neutre"),
        ],
        journalEntry: "La lampe de Keravel : 3 pièces (Courlis, Corne de brume, Salines) et une braise manquante.",
        setFlags: ["journal-lu", "quete-lampe-active"],
        rewards: { unlockAbilities: ["carte-hydrographique"] },
      }),
      part({
        id: "c02-p3", title: "Un établi de fortune", zone: "prairie-phare",
        summary: "Le joueur construit son premier établi pour fabriquer outils et pioche.",
        objectives: [collect("bois", 6, "Réunir 6 bois"), build("etabli", "Construire un établi [B]")],
        dialogue: [
          say("narrateur", "[B] Construire — un établi ouvre la fabrication d'outils.", "neutre"),
          say("releve", "Une hache, une pioche. Et ensuite, la marée.", "joyeux"),
        ],
        rewards: { unlockRecipes: ["r-hache", "r-pioche"], items: [{ item: "lanterne", count: 1 }] },
      }),
    ],
  }),

  // ---------------------------------------------------------- CH 3
  chapter({
    id: "c03", number: 3, act: 1, title: "Le Courlis",
    synopsis: "Une épave sur un îlot, accessible seulement à marée basse. Dans la cale : la lentille et un vieux marin.",
    parts: [
      part({
        id: "c03-p1", title: "La passe à marée basse", zone: "passe-courlis",
        summary: "Il faut attendre que la mer se retire pour traverser la passe.",
        objectives: [waitFor("maree-basse", "Attendre la marée basse"), goTo("le-courlis", "Traverser jusqu'au Courlis")],
        dialogue: [
          say("narrateur", "Prochaine pleine mer dans quelques secondes… puis la mer se retire.", "neutre"),
          say("releve", "Si je rate le créneau, je dors dans l'eau.", "inquiet"),
        ],
        rewards: { unlockZones: ["le-courlis"] },
      }),
      part({
        id: "c03-p2", title: "Dans la cale", zone: "le-courlis",
        summary: "Exploration de l'épave, cale inondée, crabes, lentille de Fresnel au fond.",
        objectives: [defeat("crabe-geant", 2, "Écarter 2 crabes"), interact("cale-courlis", "Plonger dans la cale"), collect("lentille", 1, "Récupérer la lentille")],
        dialogue: [
          say("narrateur", "L'eau monte déjà. La marée n'attend personne.", "inquiet"),
          say("releve", "Là ! La lentille, intacte.", "joyeux"),
        ],
        combat: { id: "cmb-courlis", arena: "le-courlis", enemies: [{ enemy: "crabe-geant", count: 2 }], rules: ["Retourner vite au pont avant la pleine mer"] },
        rewards: { items: [{ item: "lentille", count: 1 }] },
        setFlags: ["lentille-obtenue"],
      }),
      part({
        id: "c03-p3", title: "Goulven le rescapé", zone: "le-courlis",
        summary: "Un vieux marin vit encore dans la cabine. Il parle de la Brume et d'une île au-delà d'Iroise.",
        objectives: [talk("goulven", "Parler au vieil homme")],
        dialogue: [
          say("goulven", "Le phare s'est éteint la nuit où la braise a disparu. Depuis, la Brume bouffe les navires.", "colere"),
          say("goulven", "Je l'ai vu, moi, un feu vert filer vers l'ouest. Vers Enez-Aerouant, l'île du dragon.", "mysterieux"),
          say("releve", "Un dragon ? Sérieusement ?", "inquiet"),
          say("goulven", "Ris donc. La mer, elle, n'a jamais ri.", "solennel"),
        ],
        journalEntry: "Goulven parle d'un feu vert vu filer vers Enez-Aerouant, à l'ouest, au-delà de la Mer d'Iroise.",
        setFlags: ["goulven-rencontre", "enez-aerouant-evoquee"],
      }),
    ],
  }),

  // ---------------------------------------------------------- CH 4
  chapter({
    id: "c04", number: 4, act: 1, title: "La Corne de Brume",
    synopsis: "Un îlot au nord, un treuil bloqué, et la première vraie nuit de brume.",
    parts: [
      part({
        id: "c04-p1", title: "Le Chenal du Nord", zone: "passe-nord",
        summary: "Passe plus courte, récifs traîtres : il faut chronométrer la marée.",
        objectives: [waitFor("maree-basse", "Attendre la fenêtre de marée"), goTo("corne-de-brume", "Atteindre l'îlot nord")],
        dialogue: [say("narrateur", "Basse des Dents, à gauche : rien que des dents de pierre dans la mer.", "inquiet")],
      }),
      part({
        id: "c04-p2", title: "Le treuil bloqué", zone: "corne-de-brume",
        summary: "Le réflecteur est coincé sous le treuil. Il faut caler le mécanisme avec 4 silex.",
        objectives: [collect("silex", 4, "Réunir 4 silex"), solve("treuil-corne", "Caler le treuil"), collect("reflecteur", 1, "Prendre le réflecteur")],
        dialogue: [
          say("releve", "Quatre silex, un cran… et on lâche. Doucement.", "neutre"),
          say("narrateur", "Le treuil gémit, puis libère le réflecteur de cuivre.", "neutre"),
        ],
        rewards: { items: [{ item: "reflecteur", count: 1 }] },
        setFlags: ["reflecteur-obtenu"],
      }),
      part({
        id: "c04-p3", title: "La première brume", zone: "corne-de-brume",
        summary: "La Brume arrive d'un coup. Les spectres surgissent. Seule la lanterne les repousse.",
        objectives: [survive(60, "Tenir dans la brume"), defeat("spectre-brume", 3, "Repousser 3 spectres")],
        dialogue: [
          say("narrateur", "La cloche sonne trois fois. La brume avale tout.", "mysterieux"),
          say("releve", "Ça bouge… dans le blanc.", "inquiet"),
        ],
        combat: { id: "cmb-brume-1", arena: "corne-de-brume", enemies: [{ enemy: "spectre-brume", count: 3 }], rules: ["Les spectres fuient la lumière de la lanterne"] },
        rewards: { items: [{ item: "boite-veilleur", count: 1 }] },
      }),
    ],
  }),

  // ---------------------------------------------------------- CH 5
  chapter({
    id: "c05", number: 5, act: 1, title: "L'Atelier des Salines",
    synopsis: "Une roue à eau morte et une dynamo à réparer, de nuit, dans les marais salants.",
    parts: [
      part({
        id: "c05-p1", title: "Les marais salants", zone: "ateliers-salines",
        summary: "Traversée des bassins de sel, collecte et premières traces de bottes vertes.",
        objectives: [goTo("ateliers-salines", "Atteindre l'atelier"), collect("sel", 4, "Récolter 4 sel gris")],
        dialogue: [
          say("releve", "Des bottes. Vertes, avec de la boue de mine…", "inquiet"),
          say("narrateur", "Quelqu'un est passé ici avant toi, et récemment.", "mysterieux"),
        ],
        setFlags: ["traces-vertes-1"],
      }),
      part({
        id: "c05-p2", title: "La dynamo coincée", zone: "ateliers-salines",
        summary: "La roue est bloquée, il faut la débloquer puis réparer la dynamo avec 4 bois.",
        objectives: [collect("bois", 4, "Réunir 4 bois"), solve("roue-salines", "Débloquer la roue à eau"), collect("dynamo", 1, "Récupérer la dynamo")],
        dialogue: [
          say("releve", "La roue tourne ! Le sel craque sous mes bottes.", "joyeux"),
          say("narrateur", "La dynamo est lourde, mais elle respire encore.", "neutre"),
        ],
        rewards: { items: [{ item: "dynamo", count: 1 }] },
        setFlags: ["dynamo-obtenue"],
      }),
      part({
        id: "c05-p3", title: "Retour dans la nuit", zone: "prairie-phare",
        summary: "Il faut rentrer au phare avant que la Chaleur ne chute.",
        objectives: [waitFor("nuit", "La nuit tombe"), survive(60, "Tenir jusqu'au phare"), goTo("phare-keravel", "Atteindre le phare")],
        dialogue: [
          say("releve", "Les trois pièces sont là. Il manque la braise.", "neutre"),
          say("narrateur", "Au loin, la cloche sonne une dernière fois.", "mysterieux"),
        ],
        setFlags: ["trois-pieces-reunies"],
      }),
    ],
  }),

  // ---------------------------------------------------------- CH 6
  chapter({
    id: "c06", number: 6, act: 1, title: "La Braise Manquante",
    synopsis: "On assemble la lampe, mais sans braise, la lumière est faible. Le faisceau révèle une lueur verte.",
    parts: [
      part({
        id: "c06-p1", title: "Assembler la lampe", zone: "phare-keravel",
        summary: "Lentille, réflecteur et dynamo prennent place dans la salle de la lanterne.",
        objectives: [interact("poser-lentille", "Poser la lentille, le réflecteur et la dynamo"), interact("lanterne-assemblage", "Assembler la lanterne")],
        dialogue: [
          say("narrateur", "Chaque pièce s'emboîte avec un claquement sec.", "neutre"),
          say("releve", "Elle est là. Il ne lui manque plus que son cœur.", "solennel"),
        ],
        setFlags: ["lampe-assemblee"],
      }),
      part({
        id: "c06-p2", title: "L'allumage", zone: "phare-keravel",
        summary: "On allume avec une braise de fortune. Le phare s'éclaire faiblement et un point vert apparaît à l'ouest.",
        objectives: [craft("braise-fortune", "Préparer une braise de fortune"), interact("allumer-phare", "Allumer le phare")],
        dialogue: [
          say("releve", "Allez… allez…", "inquiet"),
          say("narrateur", "Un faisceau pâle traverse la Brume. Très loin, une lueur verte répond.", "mysterieux"),
          say("goulven", "(Au loin) Elle est vivante, notre vieille lampe !", "joyeux"),
        ],
        rewards: { lampPower: 35 },
        setFlags: ["phare-allume-faible", "lueur-verte-vue"],
      }),
      part({
        id: "c06-p3", title: "La lettre d'Ewen", zone: "phare-keravel",
        summary: "Un message arrive par pigeon : se rendre à Trois-Vannes, voir la doyenne Soizic.",
        objectives: [interact("pigeon-ewen", "Lire la lettre"), goTo("route-trois-vannes", "Prendre la route de Trois-Vannes")],
        dialogue: [
          say("ewen", "(Lettre) Beau travail. Mais une braise ordinaire ne tiendra pas. Allez à Trois-Vannes, voyez Soizic. Quelqu'un là-bas sait où est le vrai cœur du phare.", "solennel"),
          say("releve", "Le vrai cœur… Une braise pas comme les autres.", "mysterieux"),
        ],
        journalEntry: "Fin du chapitre : la lampe brille faiblement. La lueur verte vient de l'ouest. Direction Trois-Vannes.",
        setFlags: ["acte1-termine"],
        rewards: { unlockZones: ["route-trois-vannes", "tv-remparts"] },
      }),
    ],
  }),
];
