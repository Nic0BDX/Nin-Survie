import { build, chapter, collect, craft, defeat, goTo, interact, part, say, sneak, solve, survive, talk, waitFor } from "../helpers";

// ============================================================
//  ACTE III — ENEZ-AEROUANT   (la grande île extérieure)
//  Chapitres 13 à 18 · 18 parties
// ============================================================

export const act3 = [
  // ---------------------------------------------------------- CH 13
  chapter({
    id: "c13", number: 13, act: 3, title: "La Traversée",
    synopsis: "La Mer d'Iroise est capricieuse. La tempête sépare l'équipage et jette la Veilleuse sur les récifs.",
    parts: [
      part({
        id: "c13-p1", title: "La Mer d'Iroise", zone: "mer-iroise",
        summary: "Navigation à la boussole, lecture des courants, passage près de la Basse des Dents.",
        objectives: [goTo("mer-iroise", "Quitter le port"), solve("navigation-iroise", "Suivre le cap de Maëlle")],
        dialogue: [
          say("maelle", "Cap ouest-sud-ouest. Si la brume épaissit, on suit le bruit des vagues sur les dents.", "neutre"),
          say("goulven", "La mer écoute. Parle-lui poliment.", "joyeux"),
        ],
      }),
      part({
        id: "c13-p2", title: "La tempête", zone: "mer-iroise",
        summary: "Vagues, éclairs, voile déchirée. Il faut tenir la barre et écoper.",
        objectives: [survive(75, "Survivre à la tempête"), solve("ecoper", "Écoper la coque")],
        dialogue: [
          say("goulven", "Tiens la barre ! Je descends refermer la brèche !", "colere"),
          say("narrateur", "Au-dessus des vagues, une ombre immense traverse les nuages. Une seconde. Pas plus.", "mysterieux"),
          say("maelle", "Tu as vu ça ?!", "inquiet"),
        ],
        setFlags: ["ombre-dragon-vue"],
      }),
      part({
        id: "c13-p3", title: "Naufrage", zone: "ea-plage-naufrages",
        summary: "La Veilleuse s'échoue sur la Plage des Naufragés. L'équipage est dispersé.",
        cinematic: "Fondu au noir sur le fracas de la coque, puis lumière blanche sur le sable noir.",
        objectives: [goTo("ea-plage-naufrages", "Atteindre la plage")],
        dialogue: [
          say("narrateur", "Le sable est noir. Les épaves sont nombreuses. Certaines sont très anciennes.", "mysterieux"),
          say("releve", "Goulven ? Maëlle ?", "inquiet"),
        ],
        setFlags: ["naufrage"],
        rewards: { unlockZones: ["ea-plage-naufrages", "ea-sentier-embruns", "ea-embouchure"] },
      }),
    ],
  }),

  // ---------------------------------------------------------- CH 14
  chapter({
    id: "c14", number: 14, act: 3, title: "Les Naufragés",
    synopsis: "Survie sur une île inconnue : retrouver ses compagnons, bâtir un camp, comprendre la Garde.",
    parts: [
      part({
        id: "c14-p1", title: "Réveil sur le sable noir", zone: "ea-plage-naufrages",
        summary: "Récupérer les débris utiles de la Veilleuse, éviter les goélands pillards.",
        objectives: [collect("bois", 8, "Récupérer du bois d'épave"), collect("rations", 2, "Retrouver des vivres"), defeat("goeland-pillard", 2, "Chasser 2 goélands")],
        dialogue: [
          say("narrateur", "La Chaleur chute vite sur cette côte battue par le vent.", "neutre"),
          say("releve", "Un feu, d'abord. Ensuite, on cherche.", "neutre"),
        ],
      }),
      part({
        id: "c14-p2", title: "Un camp de base", zone: "ea-camp-base",
        summary: "Construire un abri, un feu et un établi pour tenir sur l'île.",
        objectives: [collect("bois", 10, "Réunir 10 bois"), build("abri", "Construire un abri"), build("etabli", "Construire un établi"), craft("braise-fortune", "Allumer le feu")],
        dialogue: [
          say("releve", "Ce n'est pas un phare, mais ça tiendra.", "joyeux"),
        ],
        setFlags: ["camp-base-construit"],
      }),
      part({
        id: "c14-p3", title: "Les premières traces", zone: "ea-sentier-embruns", 
        summary: "Des traces de bottes vertes mènent à une patrouille de la Garde, et à Maëlle, prisonnière.",
        objectives: [sneak("ea-sentier-embruns", "Suivre la patrouille sans se faire repérer"), interact("maelle-prisonniere", "Libérer Maëlle")],
        dialogue: [
          say("maelle", "Ils m'ont prise pour une espionne du Service des feux. Ils n'ont pas tort.", "joyeux"),
          say("maelle", "Goulven est vivant, il a rejoint les marais. J'ai vu sa barque.", "inquiet"),
        ],
        combat: { id: "cmb-patrouille-1", arena: "ea-sentier-embruns", enemies: [{ enemy: "garde-recrue", count: 3 }], rules: ["Possible de contourner par furtivité"] },
        setFlags: ["maelle-libre", "garde-rencontree"],
      }),
    ],
  }),

  // ---------------------------------------------------------- CH 15
  chapter({
    id: "c15", number: 15, act: 3, title: "La Stêr-Glas",
    synopsis: "Remonter la rivière verte : gué, pont de corde, cascade et grotte secrète.",
    parts: [
      part({
        id: "c15-p1", title: "Le gué des Lavandières", zone: "ea-gue-lavandieres",
        summary: "Traverser un gué peu profond en évitant les courants et les loups d'eau douce.",
        objectives: [goTo("ea-embouchure", "Rejoindre l'embouchure"), goTo("ea-gue-lavandieres", "Atteindre le gué"), solve("gue-pierres", "Traverser sur les pierres plates")],
        dialogue: [
          say("maelle", "Les pierres plates sont à six pas du bord. Ne regarde pas l'eau, regarde tes pieds.", "neutre"),
        ],
      }),
      part({
        id: "c15-p2", title: "Le pont de corde de Pen-Stêr", zone: "ea-pont-de-corde",
        summary: "Un pont suspendu surveillé par deux gardes. Combat, furtivité ou diversion.",
        objectives: [goTo("ea-pont-de-corde", "Approcher du pont"), defeat("garde-arbalete", 2, "Neutraliser les arbalétriers", )],
        dialogue: [
          say("ronan", "(Garde, de loin) Qui va là ?! … Personne. Retourne à ta ronde, Yvon.", "inquiet"),
          say("maelle", "Celui-là ne veut pas qu'on le trouve. Étrange.", "mysterieux"),
        ],
        combat: { id: "cmb-pont", arena: "ea-pont-de-corde", enemies: [{ enemy: "garde-arbalete", count: 2 }, { enemy: "garde-lance", count: 1 }], rules: ["Couper la corde fait tomber les gardes dans la rivière"] },
      }),
      part({
        id: "c15-p3", title: "La cascade du Voile", zone: "ea-cascade-voile",
        summary: "Derrière le rideau d'eau, une grotte secrète cache la deuxième boîte des veilleurs.",
        objectives: [goTo("ea-cascade-voile", "Atteindre la cascade"), goTo("ea-grotte-voile", "Passer derrière le Voile"), collect("boite-veilleur", 1, "Prendre la boîte n°2")],
        dialogue: [
          say("narrateur", "Un souvenir gravé : « On n'a pas tué le dragon. On l'a rendu au sommeil. »", "mysterieux"),
          say("releve", "Ils l'ont endormi. Pas vaincu.", "inquiet"),
        ],
        setFlags: ["boite-2"],
        rewards: { items: [{ item: "boite-veilleur", count: 1 }] },
      }),
    ],
  }),

  // ---------------------------------------------------------- CH 16
  chapter({
    id: "c16", number: 16, act: 3, title: "La Forêt de Coat-Du",
    synopsis: "Une forêt sombre pleine de feux follets où un cerf spectral garde le chemin du sud.",
    parts: [
      part({
        id: "c16-p1", title: "Sous les arbres", zone: "ea-foret-coat-du",
        summary: "Loups, racines pièges, nuit permanente. La lanterne devient indispensable.",
        objectives: [goTo("ea-foret-coat-du", "Entrer dans la forêt"), defeat("loup-des-landes", 3, "Repousser la meute")],
        dialogue: [
          say("maelle", "Les arbres ont mangé la lumière. Garde ta lanterne haute.", "inquiet"),
        ],
        combat: { id: "cmb-loups", arena: "ea-foret-coat-du", enemies: [{ enemy: "loup-des-landes", count: 3 }] },
      }),
      part({
        id: "c16-p2", title: "Les feux follets", zone: "ea-foret-coat-du",
        summary: "Suivre les bonnes lueurs, ignorer les mauvaises : puzzle de lumières.",
        objectives: [solve("feux-follets", "Suivre la bonne lueur", )],
        dialogue: [
          say("narrateur", "Trois lueurs dansent. Deux mentent.", "mysterieux"),
          say("releve", "La seule qui ne bouge pas quand je cligne des yeux…", "neutre"),
        ],
      }),
      part({
        id: "c16-p3", title: "Le Cerf de Brume", zone: "ea-coeur-foret",
        summary: "Mini-boss : un cerf gigantesque fait de brume et de ramures.",
        objectives: [defeat("cerf-de-brume", 1, "Vaincre le Cerf de Brume")],
        dialogue: [
          say("narrateur", "Il ne veut pas vous tuer. Il veut que vous partiez.", "mysterieux"),
        ],
        combat: { id: "cmb-cerf", arena: "ea-coeur-foret", enemies: [{ enemy: "cerf-de-brume", count: 1 }], boss: "cerf-de-brume", rules: ["Éclairer le cerf avec la lanterne pour l'étourdir"] },
        rewards: { unlockAbilities: ["lanterne-vive"] },
      }),
    ],
  }),

  // ---------------------------------------------------------- CH 17
  chapter({
    id: "c17", number: 17, act: 3, title: "Les Marais de Stank et Ker-Goz",
    synopsis: "Marais toxique, village abandonné, retrouvailles avec Goulven, et un serpent géant.",
    parts: [
      part({
        id: "c17-p1", title: "Le marais", zone: "ea-marais-stank",
        summary: "Poison, brume, ponts de planches pourris. Nolwenn a laissé une recette d'antidote.",
        objectives: [collect("herbe-marais", 3, "Cueillir 3 herbes de marais"), craft("antidote", "Préparer l'antidote")],
        dialogue: [
          say("maelle", "Ne touche pas aux nénuphars violets. Ils collent.", "inquiet"),
        ],
      }),
      part({
        id: "c17-p2", title: "Ker-Goz, le village vidé", zone: "ea-ker-goz",
        summary: "Le vieux village de pêcheurs a été vidé par la Garde. Goulven et quelques survivants s'y cachent.",
        objectives: [goTo("ea-ker-goz", "Atteindre Ker-Goz"), talk("goulven", "Retrouver Goulven")],
        dialogue: [
          say("goulven", "Ils les ont envoyés aux mines. Hommes, femmes, tout ce qui peut porter un seau.", "colere"),
          say("goulven", "Le Baron n'est pas un voleur. C'est un roi qui s'ignore.", "solennel"),
        ],
        setFlags: ["goulven-retrouve", "mineurs-captifs-connus"],
      }),
      part({
        id: "c17-p3", title: "Le Serpent de Stank", zone: "ea-antre-serpent",
        summary: "Mini-boss : un serpent colossal qui garde l'unique passage vers les landes.",
        objectives: [defeat("serpent-de-stank", 1, "Vaincre le Serpent de Stank")],
        dialogue: [
          say("goulven", "Frappe la tête quand il sort ! Pas avant !", "colere"),
        ],
        combat: { id: "cmb-serpent", arena: "ea-antre-serpent", enemies: [{ enemy: "serpent-de-stank", count: 1 }], boss: "serpent-de-stank" },
        rewards: { items: [{ item: "fer", count: 2 }] },
      }),
    ],
  }),

  // ---------------------------------------------------------- CH 18
  chapter({
    id: "c18", number: 18, act: 3, title: "Les Ruines des Veilleurs",
    synopsis: "Un ancien phare effondré cache le dernier veilleur et la vérité sur le dragon.",
    parts: [
      part({
        id: "c18-p1", title: "Les gorges de Roc'h-Gwenn", zone: "ea-gorges-rochgwenn",
        summary: "Falaises blanches, passerelles instables, un golem de schiste en travers du chemin.",
        objectives: [goTo("ea-landes-brug", "Traverser les Landes de Brug"), goTo("ea-gorges-rochgwenn", "Entrer dans les gorges"), defeat("golem-de-schiste", 1, "Briser le golem")],
        dialogue: [
          say("maelle", "Son cœur brille dans son dos. Vise-le avec une arbalète.", "neutre"),
        ],
        combat: { id: "cmb-golem", arena: "ea-gorges-rochgwenn", enemies: [{ enemy: "golem-de-schiste", count: 1 }], boss: "golem-de-schiste" },
      }),
      part({
        id: "c18-p2", title: "Erwan Le Bris", zone: "ea-ruines-veilleurs",
        summary: "Le dernier veilleur, vieilli, survit dans les ruines depuis trois ans.",
        objectives: [goTo("ea-ruines-veilleurs", "Explorer les ruines"), talk("erwan", "Parler à Erwan")],
        dialogue: [
          say("erwan", "Je savais qu'une relève viendrait. Je n'espérais pas qu'elle survive.", "triste"),
          say("erwan", "C'est le Baron. Il a pris le Kalon-Glas dans la lanterne, la nuit des cloches. Je n'ai rien pu faire.", "triste"),
          say("releve", "Pourquoi la Brume ? Pourquoi ces spectres ?", "inquiet"),
        ],
        setFlags: ["erwan-retrouve"],
      }),
      part({
        id: "c18-p3", title: "La clé de braise", zone: "ea-ruines-veilleurs",
        summary: "Erwan révèle la vérité sur Aerouant, donne la clé de la Salle Verte et la troisième boîte.",
        objectives: [collect("boite-veilleur", 1, "Prendre la boîte n°3"), collect("cle-braise", 1, "Recevoir la clé de braise")],
        dialogue: [
          say("erwan", "Aerouant n'est pas un monstre né pour détruire. C'est un feu ancien. Nos ancêtres lui ont pris son cœur, le Kalon-Glas, pour le dompter.", "solennel"),
          say("erwan", "Tant que la lumière verte brille dans le phare, il dort. Sans elle, il se réveille. Doucement. Il rêve déjà.", "inquiet"),
          say("erwan", "Prenez la clé. Mais promettez-moi une chose : quand vous aurez l'émeraude, ne la gardez pas. Rapportez-la au phare. Vite.", "solennel"),
        ],
        journalEntry: "Vérité : le Kalon-Glas est le cœur du dragon. Le phare l'endort par sa lumière verte. Ramener l'émeraude au phare, vite.",
        setFlags: ["verite-aerouant", "acte3-termine"],
        rewards: { items: [{ item: "cle-braise", count: 1 }, { item: "boite-veilleur", count: 1 }], reputation: { veilleurs: 20 }, unlockZones: ["ea-camp-garde"] },
      }),
    ],
  }),
];
