import { build, chapter, defeat, goTo, interact, part, say, solve, survive, talk } from "../helpers";

// ============================================================
//  ACTE V — LE DRAGON   (de l'île à Trois-Vannes, puis au phare)
//  Chapitres 25 à 30 · 18 parties
// ============================================================

export const act5 = [
  // ---------------------------------------------------------- CH 25
  chapter({
    id: "c25", number: 25, act: 5, title: "La Fuite sous les Cendres",
    synopsis: "La citadelle s'effondre, la lave descend, l'île entière brûle. Il faut atteindre la côte.",
    parts: [
      part({
        id: "c25-p1", title: "L'effondrement", zone: "ea-citadelle-donjon",
        summary: "Course dans les escaliers du donjon pendant que les murs s'écroulent.",
        objectives: [survive(45, "Descendre avant l'effondrement"), goTo("ea-citadelle-cour", "Atteindre la cour")],
        dialogue: [
          say("ronan", "Par ici ! L'escalier de service tient encore !", "colere"),
          say("maelle", "Le sol se fend ! Saute !", "inquiet"),
        ],
      }),
      part({
        id: "c25-p2", title: "Les landes en feu", zone: "ea-crete-vents",
        summary: "Course à travers la crête et les landes sous une pluie de cendres et de roches brûlantes.",
        objectives: [goTo("ea-crete-vents", "Franchir la Crête des Vents"), survive(60, "Esquiver les roches de lave")],
        dialogue: [
          say("narrateur", "Le ciel devient orange. Les menhirs fondent comme du sucre.", "mysterieux"),
          say("goulven", "Je n'ai jamais couru aussi vite depuis mes vingt ans !", "joyeux"),
        ],
      }),
      part({
        id: "c25-p3", title: "Le dernier bateau", zone: "ea-plage-naufrages",
        summary: "La Veilleuse, réparée en secret par les rescapés de Ker-Goz, attend sur la plage.",
        objectives: [goTo("ea-plage-naufrages", "Atteindre la plage"), interact("veilleuse-embarquer", "Embarquer sur la Veilleuse")],
        dialogue: [
          say("goulven", "Je l'ai raboutée comme j'ai pu. Elle flotte. Elle fera le reste.", "joyeux"),
          say("orwenn", "(Si épargnée) Je tiens la poupe. La Garde a un devoir de plus.", "solennel"),
        ],
        setFlags: ["fuite-reussie"],
      }),
    ],
  }),

  // ---------------------------------------------------------- CH 26
  chapter({
    id: "c26", number: 26, act: 5, title: "Le Réveil d'Aerouant",
    synopsis: "Le dragon surgit du volcan, poursuit la Veilleuse au-dessus d'Iroise, parle.",
    parts: [
      part({
        id: "c26-p1", title: "Le dragon sur la mer", zone: "mer-iroise",
        summary: "Poursuite à bord de la Veilleuse : harpons, voile, esquive des jets de feu.",
        cinematic: "Le dragon surgit du cratère, ailes déployées, éclipse la lune. Plan large sur la Veilleuse minuscule.",
        objectives: [survive(90, "Tenir la mer pendant la poursuite"), solve("harpon-aile", "Harponner une aile du dragon")],
        dialogue: [
          say("goulven", "Tribord toute ! Il vise la voile !", "colere"),
          say("maelle", "Les harpons ! Maintenant !", "inquiet"),
        ],
      }),
      part({
        id: "c26-p2", title: "La voix du dragon", zone: "mer-iroise",
        summary: "Aerouant s'approche de la Veilleuse et parle au porteur du Kalon-Glas.",
        objectives: [talk("aerouant", "Écouter le dragon")],
        dialogue: [
          say("aerouant", "Petit veilleur… tu portes mon cœur dans une main d'humain.", "mysterieux"),
          say("aerouant", "Vos ancêtres l'ont arraché. Ils ont appelé cela un sommeil. Moi, j'ai appelé cela une prison.", "colere"),
          say("releve", "Si je te le rends, tu brûleras Keravel.", "solennel"),
          say("aerouant", "Peut-être. Peut-être pas. Tu veux parier ?", "joyeux"),
        ],
        setFlags: ["dragon-parle"],
      }),
      part({
        id: "c26-p3", title: "La côte de Keravel", zone: "mer-iroise",
        summary: "Le dragon coupe la route. Il prend de l'avance vers Trois-Vannes.",
        objectives: [goTo("tv-port", "Rejoindre le port de Trois-Vannes")],
        dialogue: [
          say("maelle", "Il vole droit sur le village !", "inquiet"),
          say("releve", "On sonne la cloche. Toutes les cloches.", "solennel"),
        ],
        journalEntry: "Aerouant s'est dirigé vers Trois-Vannes. Il faut ramener le Kalon-Glas au phare, mais d'abord sauver le village.",
      }),
    ],
  }),

  // ---------------------------------------------------------- CH 27
  chapter({
    id: "c27", number: 27, act: 5, title: "Trois-Vannes sous le Feu",
    synopsis: "Phase 1 du combat : le dragon attaque le village par les airs. Tout le village se défend.",
    parts: [
      part({
        id: "c27-p1", title: "L'alerte", zone: "tv-place-cloche",
        summary: "Sonner la grande cloche, évacuer les habitants, armer les balistes.",
        objectives: [interact("grande-cloche", "Sonner la grande cloche"), talk("soizic", "Rejoindre Soizic")],
        dialogue: [
          say("soizic", "Tout le monde aux caves de la chapelle ! Les armes à la halle !", "colere"),
          say("tangi", "Mes balistes sont prêtes. Montrez-moi où tirer.", "solennel"),
        ],
      }),
      part({
        id: "c27-p2", title: "Les balistes de Tangi", zone: "tv-port",
        summary: "Phase 1 du boss : viser les ailes avec les balistes pendant que le dragon passe en rase-mottes.",
        objectives: [defeat("aerouant", 1, "Faire atterrir le dragon (phase 1)")],
        dialogue: [
          say("yannig", "Je charge ! Vous, visez !", "joyeux"),
          say("aerouant", "Petites flèches. Petits toits. Petit monde.", "mysterieux"),
        ],
        combat: { id: "boss-aerouant-p1", arena: "tv-port", enemies: [{ enemy: "aerouant", count: 1 }], boss: "aerouant", rules: ["Phase 1 : Le Ciel de Feu", "Les balistes infligent 3 fois plus de dégâts aux ailes"] },
      }),
      part({
        id: "c27-p3", title: "Le port en flammes", zone: "tv-port",
        summary: "Sauvetage de villageois coincés, et Yannig en danger.",
        objectives: [survive(60, "Éteindre les incendies"), interact("yannig-sauvetage", "Sauver Yannig")],
        dialogue: [
          say("yannig", "Je suis là ! Sous la poutre !", "inquiet"),
          say("releve", "Accroche-toi. Je te sors de là.", "solennel"),
          say("aerouant", "(Il se pose) Le cœur. Maintenant.", "colere"),
        ],
        setFlags: ["yannig-sauve", "dragon-atterri"],
      }),
    ],
  }),

  // ---------------------------------------------------------- CH 28
  chapter({
    id: "c28", number: 28, act: 5, title: "Le Combat au Pied du Phare",
    synopsis: "Le dragon poursuit la relève jusqu'à la prairie du phare : bataille au sol, puis ascension de la tour.",
    parts: [
      part({
        id: "c28-p1", title: "Gravir la colline", zone: "route-trois-vannes",
        summary: "Courir de Trois-Vannes au phare avec le Kalon-Glas en harcelant le dragon.",
        objectives: [survive(60, "Fuir sur la route côtière"), goTo("prairie-phare", "Atteindre la Prairie du Phare")],
        dialogue: [
          say("maelle", "Le phare, c'est la seule chose qu'il craint ! Cours !", "inquiet"),
        ],
      }),
      part({
        id: "c28-p2", title: "Aerouant au sol", zone: "prairie-phare",
        summary: "Phase 2 : combat au sol, queue, morsure, souffle en cône. Utiliser les rochers et la barrière comme abris.",
        objectives: [defeat("aerouant", 1, "Réduire le dragon à 40 % de PV (phase 2)")],
        dialogue: [
          say("aerouant", "Ici, tout a commencé. Ici, tout finira.", "solennel"),
        ],
        combat: { id: "boss-aerouant-p2", arena: "prairie-phare", enemies: [{ enemy: "aerouant", count: 1 }], boss: "aerouant", rules: ["Phase 2 : Le Dragon au Sol", "Ventre exposé après chaque souffle"] },
      }),
      part({
        id: "c28-p3", title: "La lanterne", zone: "phare-keravel",
        summary: "Monter dans le phare pendant que le dragon grimpe sur la tour.",
        objectives: [goTo("phare-keravel", "Entrer dans le phare"), survive(40, "Gravir l'escalier"), goTo("phare-keravel", "Atteindre la salle de la lanterne")],
        dialogue: [
          say("ronan", "Je retiens la porte du bas !", "colere"),
          say("erwan", "(Écho) Tout en haut. Le Kalon-Glas va dans la braise. Maintenant.", "solennel"),
        ],
      }),
    ],
  }),

  // ---------------------------------------------------------- CH 29
  chapter({
    id: "c29", number: 29, act: 5, title: "La Lumière Verte",
    synopsis: "Insérer l'émeraude, tourner le faisceau, affronter la fin du dragon, et choisir.",
    parts: [
      part({
        id: "c29-p1", title: "Insérer le Kalon-Glas", zone: "phare-keravel",
        summary: "Phase 3 : placer le Kalon-Glas dans la lampe sous les assauts du dragon.",
        objectives: [interact("inserer-kalon-glas", "Insérer le Kalon-Glas dans la lanterne")],
        dialogue: [
          say("releve", "Allez… prends ta place, petite lumière.", "solennel"),
          say("narrateur", "La lanterne s'illumine d'un vert profond. Toute l'île s'éclaire.", "mysterieux"),
        ],
        combat: { id: "boss-aerouant-p3", arena: "phare-keravel", enemies: [{ enemy: "aerouant", count: 1 }], boss: "aerouant", rules: ["Phase 3 : La Lumière Verte"] },
        rewards: { lampPower: 100 },
        setFlags: ["kalon-glas-insere"],
      }),
      part({
        id: "c29-p2", title: "Le faisceau", zone: "phare-keravel",
        summary: "Phase 4 : orienter le faisceau vers le dragon pour l'étourdir et l'affaiblir.",
        objectives: [defeat("aerouant", 1, "Maintenir le faisceau sur le dragon (phase 4)")],
        dialogue: [
          say("aerouant", "Cette lumière… je m'en souviens…", "triste"),
          say("maelle", "Il faiblit ! Garde le cap !", "joyeux"),
        ],
        combat: { id: "boss-aerouant-p4", arena: "phare-keravel", enemies: [{ enemy: "aerouant", count: 1 }], boss: "aerouant", rules: ["Phase 4 : L'Agonie de Braise", "Séquence de timing du faisceau"] },
      }),
      part({
        id: "c29-p3", title: "Le choix", zone: "phare-keravel",
        summary: "Le dragon est à genoux. Trois fins possibles.",
        objectives: [talk("aerouant", "Décider du sort du dragon")],
        dialogue: [
          say("aerouant", "Alors, veilleur ? Une prison, une mort, ou un adieu ?", "solennel"),
        ],
        choices: [{
          id: "fin-dragon", prompt: "Que faire d'Aerouant ?",
          options: [
            { id: "sceller", label: "Le rendormir avec la lumière verte", setFlags: ["fin-veilleur"], reputation: { veilleurs: 30 }, consequence: "Fin « La Flamme Gardée » : le phare brille pour toujours." },
            { id: "tuer", label: "Porter le coup final", setFlags: ["fin-chasseur"], reputation: { garde: 20 }, consequence: "Fin « Le Dernier Coup » : la Brume disparaît mais le phare s'éteint." },
            { id: "liberer", label: "Lui rendre son cœur", setFlags: ["fin-liberation"], reputation: { veilleurs: -10 }, consequence: "Fin « La Paix de Braise » : le dragon part, Keravel est libre mais sans protection." },
          ],
        }],
        setFlags: ["dragon-vaincu"],
      }),
    ],
  }),

  // ---------------------------------------------------------- CH 30
  chapter({
    id: "c30", number: 30, act: 5, title: "Après la Brume",
    synopsis: "L'aube sur Keravel. Conséquences, reconstruction, épilogue, et monde libre.",
    parts: [
      part({
        id: "c30-p1", title: "L'aube", zone: "phare-keravel",
        summary: "Le soleil se lève, la Brume se dissipe. Chaque fin a son plan final.",
        cinematic: "Aube sur la mer. Le phare, rouge et blanc, domine l'archipel. La caméra monte au-dessus des nuages.",
        objectives: [goTo("phare-keravel", "Sortir sur le balcon")],
        dialogue: [
          say("narrateur", "La cloche sonne une dernière fois. Pour la première fois depuis trois ans, elle sonne l'aurore.", "solennel"),
        ],
      }),
      part({
        id: "c30-p2", title: "Trois-Vannes se relève", zone: "tv-place-cloche",
        summary: "Reconstruction : le joueur aide à rebâtir le village, avec les gens qu'il a aidés.",
        objectives: [build("reconstruction-port", "Reconstruire le port"), talk("soizic", "Parler à Soizic")],
        dialogue: [
          say("soizic", "Nous avons perdu des toits. Nous avons gagné un ciel.", "joyeux"),
          say("yannig", "Je te garde une chambre à l'auberge. À vie.", "joyeux"),
          say("tangi", "(Il pose une plaque de fer gravée au phare) Pour le veilleur.", "solennel"),
        ],
      }),
      part({
        id: "c30-p3", title: "Le veilleur de Keravel", zone: "phare-keravel",
        summary: "Épilogue : le joueur devient le veilleur officiel, le monde reste ouvert.",
        objectives: [interact("journal-veilleur-final", "Signer le journal du phare")],
        dialogue: [
          say("ewen", "(Lettre) Vous êtes désormais veilleur de Keravel. Gardez la flamme.", "solennel"),
          say("releve", "Toujours.", "joyeux"),
        ],
        journalEntry: "Fin de l'histoire principale. Monde libre : retrouver les boîtes des veilleurs, explorer Enez-Aerouant, aider Trois-Vannes.",
        setFlags: ["histoire-terminee", "acte5-termine"],
        rewards: { unlockAbilities: ["monde-libre", "nouvelle-partie-plus"] },
      }),
    ],
  }),
];
