import { chapter, collect, defeat, goTo, interact, part, say, sneak, solve, survive, talk } from "../helpers";

// ============================================================
//  ACTE IV — LA CITADELLE DE KASTELL-GLAS   (l'émeraude et ses gardes)
//  Chapitres 19 à 24 · 18 parties
// ============================================================

export const act4 = [
  // ---------------------------------------------------------- CH 19
  chapter({
    id: "c19", number: 19, act: 4, title: "Le Camp de la Garde",
    synopsis: "Observer, infiltrer, convaincre : le camp est la porte de la citadelle.",
    parts: [
      part({
        id: "c19-p1", title: "Observer depuis la lande", zone: "ea-landes-brug",
        summary: "Depuis un menhir, la relève étudie les rondes, les tours et les relèves.",
        objectives: [goTo("ea-landes-brug", "Atteindre le menhir de guet"), interact("longue-vue", "Observer le camp avec la longue-vue")],
        dialogue: [
          say("maelle", "Trois tours, deux relèves par nuit, un feu au centre. Et un lieutenant qui regarde la mer plus que ses hommes.", "neutre"),
        ],
      }),
      part({
        id: "c19-p2", title: "Trois façons d'entrer", zone: "ea-camp-garde",
        summary: "Choix d'approche : furtivité, combat ou diplomatie.",
        objectives: [goTo("ea-camp-garde", "Atteindre le camp")],
        dialogue: [
          say("goulven", "Furtif, c'est long. Frontal, c'est sanglant. Parler, c'est risqué. Choisis ton poison.", "neutre"),
        ],
        choices: [{
          id: "entree-camp", prompt: "Comment entrer dans le camp ?",
          options: [
            { id: "furtif", label: "Se glisser avec l'uniforme volé", setFlags: ["camp-furtif"], consequence: "Aucun alarme, mais pas de renforts." },
            { id: "force", label: "Attaquer de front", setFlags: ["camp-force"], reputation: { garde: -10 }, consequence: "Alarme générale, mais la Garde se disperse." },
            { id: "parler", label: "Demander à parler au lieutenant Ronan", setFlags: ["camp-diplomatie"], reputation: { garde: 10 }, consequence: "Ronan devient allié plus tôt." },
          ],
        }],
        combat: { id: "cmb-camp", arena: "ea-camp-garde", enemies: [{ enemy: "garde-recrue", count: 4 }, { enemy: "garde-lance", count: 2 }, { enemy: "garde-bouclier", count: 1 }], rules: ["Uniquement si l'option « force » est choisie"] },
      }),
      part({
        id: "c19-p3", title: "Le renégat", zone: "ea-camp-garde",
        summary: "Ronan, jeune lieutenant, avoue ne plus croire au Baron et offre son aide.",
        objectives: [talk("ronan", "Parler à Ronan")],
        dialogue: [
          say("ronan", "On m'a dit que je protégeais l'île. J'ai vu des familles enchaînées.", "triste"),
          say("ronan", "Je vous ouvre la petite porte des mines. Après, je n'ai rien vu.", "inquiet"),
          say("releve", "Merci, Ronan.", "joyeux"),
        ],
        setFlags: ["ronan-allie"],
        rewards: { reputation: { garde: 15 } },
      }),
    ],
  }),

  // ---------------------------------------------------------- CH 20
  chapter({
    id: "c20", number: 20, act: 4, title: "Les Mines Vertes",
    synopsis: "Libérer les mineurs, découvrir ce que le Baron fait de la poussière d'émeraude.",
    parts: [
      part({
        id: "c20-p1", title: "L'entrée des mines", zone: "ea-mines-vertes",
        summary: "Galeries étroites, wagonnets, poussière verte qui brille.",
        objectives: [goTo("ea-mines-vertes", "Entrer dans les mines"), collect("poussiere-emeraude", 3, "Examiner la poussière d'émeraude")],
        dialogue: [
          say("narrateur", "La poussière verte brille faiblement. Elle est chaude, comme un cœur.", "mysterieux"),
        ],
      }),
      part({
        id: "c20-p2", title: "Les mineurs enchaînés", zone: "ea-mines-vertes",
        summary: "Libérer les villageois de Ker-Goz et de Trois-Vannes détenus par la Garde.",
        objectives: [defeat("garde-recrue", 3, "Neutraliser les surveillants"), interact("chaines-mineurs", "Briser les chaînes")],
        dialogue: [
          say("narrateur", "Un vieux mineur lève les yeux : « C'est donc vrai, quelqu'un est venu. »", "triste"),
        ],
        combat: { id: "cmb-mineurs", arena: "ea-mines-vertes", enemies: [{ enemy: "garde-recrue", count: 3 }] },
        setFlags: ["mineurs-liberes"],
        rewards: { reputation: { "trois-vannes": 20 } },
      }),
      part({
        id: "c20-p3", title: "L'éboulement", zone: "ea-mines-vertes",
        summary: "Une galerie s'effondre : fuite à travers un passage secret menant aux cryptes de la citadelle.",
        objectives: [survive(40, "Fuir l'éboulement"), goTo("ea-citadelle-cryptes", "Atteindre les cryptes")],
        dialogue: [
          say("ronan", "La galerie est piégée ! Par ici, les cryptes !", "colere"),
          say("goulven", "J'ai connu des tempêtes plus calmes que ça !", "joyeux"),
        ],
      }),
    ],
  }),

  // ---------------------------------------------------------- CH 21
  chapter({
    id: "c21", number: 21, act: 4, title: "Les Remparts",
    synopsis: "Assaut sur les murailles, archers, herse à lever.",
    parts: [
      part({
        id: "c21-p1", title: "L'escalade silencieuse", zone: "ea-citadelle-remparts",
        summary: "Grimper aux remparts sans réveiller le guet.",
        objectives: [goTo("ea-citadelle-remparts", "Atteindre le pied des murs"), sneak("ea-citadelle-remparts", "Grimper en silence")],
        dialogue: [
          say("maelle", "La pierre est humide. Trois prises à gauche, deux à droite.", "neutre"),
        ],
      }),
      part({
        id: "c21-p2", title: "Les archers", zone: "ea-citadelle-remparts",
        summary: "Combat sur le chemin de ronde contre les arbalétriers.",
        objectives: [defeat("garde-arbalete", 4, "Éliminer les arbalétriers")],
        dialogue: [
          say("ronan", "Baissez-vous ! Ils rechargent dans quatre secondes !", "colere"),
        ],
        combat: { id: "cmb-remparts", arena: "ea-citadelle-remparts", enemies: [{ enemy: "garde-arbalete", count: 4 }, { enemy: "garde-bouclier", count: 1 }] },
      }),
      part({
        id: "c21-p3", title: "La herse", zone: "ea-citadelle-remparts",
        summary: "Lever la herse de l'intérieur pour laisser entrer les mineurs libérés.",
        objectives: [solve("treuil-herse", "Actionner le treuil de la herse"), interact("herse", "Ouvrir la herse")],
        dialogue: [
          say("narrateur", "La herse grince. Derrière, des centaines de silhouettes avancent dans la nuit.", "solennel"),
        ],
        setFlags: ["herse-ouverte"],
      }),
    ],
  }),

  // ---------------------------------------------------------- CH 22
  chapter({
    id: "c22", number: 22, act: 4, title: "La Cour d'Armes",
    synopsis: "Le cœur militaire de Kastell-Glas : combats en vagues, maître d'armes, puis la Capitaine Orwenn.",
    parts: [
      part({
        id: "c22-p1", title: "Les vagues de la cour", zone: "ea-citadelle-cour",
        summary: "Trois vagues d'ennemis dans la cour pavée, avec l'aide des mineurs.",
        objectives: [defeat("garde-lance", 3, "Vague 1 : lanciers"), defeat("garde-bouclier", 2, "Vague 2 : boucliers")],
        dialogue: [
          say("tangi", "(Mineur) J'ai ma masse. Montrez-moi qui frapper.", "joyeux"),
        ],
        combat: { id: "cmb-cour-vagues", arena: "ea-citadelle-cour", enemies: [{ enemy: "garde-lance", count: 3 }, { enemy: "garde-bouclier", count: 2 }, { enemy: "garde-recrue", count: 4 }] },
      }),
      part({
        id: "c22-p2", title: "Le Maître d'armes", zone: "ea-citadelle-cour",
        summary: "Boss duelliste rapide : parades, enchaînements à trois coups.",
        objectives: [defeat("maitre-darmes", 1, "Vaincre le Maître d'armes Kervella")],
        dialogue: [
          say("narrateur", "Le Maître d'armes salue. Pas de haine, juste du métier.", "solennel"),
        ],
        combat: { id: "cmb-maitre", arena: "ea-citadelle-cour", enemies: [{ enemy: "maitre-darmes", count: 1 }], boss: "maitre-darmes", rules: ["Esquiver le troisième coup, frapper après"] },
      }),
      part({
        id: "c22-p3", title: "La Capitaine Orwenn", zone: "ea-citadelle-cour",
        summary: "Face à face avec la Capitaine. Elle doute. Le joueur peut l'affronter ou la convaincre.",
        objectives: [talk("orwenn", "Parler à Orwenn")],
        dialogue: [
          say("orwenn", "Vous avez libéré mes mineurs. Vous avez tué mes hommes. Que voulez-vous que je fasse ?", "colere"),
          say("releve", "Que vous regardiez ce que vous protégez.", "solennel"),
          say("orwenn", "… Le Baron m'a dit qu'il sauvait l'île.", "triste"),
        ],
        choices: [{
          id: "sort-orwenn", prompt: "Que faire d'Orwenn ?",
          options: [
            { id: "combat", label: "L'affronter en duel", setFlags: ["orwenn-vaincue"], reputation: { garde: -10 }, consequence: "Boss à vaincre, elle meurt ou fuit." },
            { id: "pardon", label: "L'épargner et lui demander de se rendre", setFlags: ["orwenn-epargnee"], reputation: { garde: 20 }, consequence: "Orwenn rejoint le camp à l'acte V." },
          ],
        }],
        combat: { id: "cmb-orwenn", arena: "ea-citadelle-cour", enemies: [{ enemy: "capitaine-orwenn", count: 1 }], boss: "capitaine-orwenn", rules: ["Uniquement si le joueur choisit « combat »"] },
      }),
    ],
  }),

  // ---------------------------------------------------------- CH 23
  chapter({
    id: "c23", number: 23, act: 4, title: "Le Donjon",
    synopsis: "Six étages à gravir, des énigmes, un Baron et un piège.",
    parts: [
      part({
        id: "c23-p1", title: "L'ascension", zone: "ea-citadelle-donjon",
        summary: "Six étages, chacun avec une mécanique : leviers, ponts levis, miroirs.",
        objectives: [goTo("ea-citadelle-donjon", "Entrer dans le donjon"), solve("donjon-leviers", "Résoudre les leviers"), solve("donjon-miroirs", "Aligner les miroirs")],
        dialogue: [
          say("maelle", "Les étages sont asymétriques. Les miroirs renvoient la lumière du Kalon-Glas.", "neutre"),
        ],
      }),
      part({
        id: "c23-p2", title: "Le Baron Kerhoël", zone: "ea-citadelle-donjon",
        summary: "Duel contre le Baron, armé d'un éclat d'émeraude.",
        objectives: [defeat("baron-kerhoel", 1, "Vaincre le Baron")],
        dialogue: [
          say("kerhoel", "Vous ne comprenez pas ! Je tiens enfin Keravel dans ma main !", "colere"),
          say("kerhoel", "Cette pierre vaut dix flottes. Vous préférez des mouettes ?", "joyeux"),
          say("releve", "Elle ne vous appartient pas.", "solennel"),
        ],
        combat: { id: "cmb-baron", arena: "ea-citadelle-donjon", enemies: [{ enemy: "baron-kerhoel", count: 1 }], boss: "baron-kerhoel", rules: ["Éviter les rayons verts, frapper quand il recharge"] },
      }),
      part({
        id: "c23-p3", title: "Le piège", zone: "ea-citadelle-donjon",
        summary: "Le Baron, vaincu, déclenche un mécanisme qui scelle la Salle Verte… et l'ouvre à moitié.",
        objectives: [interact("mecanisme-salle-verte", "Désactiver le mécanisme"), interact("porte-salle-verte", "Utiliser la clé de braise")],
        dialogue: [
          say("kerhoel", "Si je ne l'ai pas, personne ne l'aura !", "colere"),
          say("erwan", "(Souvenir) La clé ne s'use qu'une fois. Choisis bien l'instant.", "mysterieux"),
        ],
        setFlags: ["baron-vaincu"],
      }),
    ],
  }),

  // ---------------------------------------------------------- CH 24
  chapter({
    id: "c24", number: 24, act: 4, title: "Le Kalon-Glas",
    synopsis: "L'émeraude est enfin devant vous. La prendre réveille le dragon.",
    parts: [
      part({
        id: "c24-p1", title: "La Salle Verte", zone: "ea-salle-verte",
        summary: "Salle ronde, lumière verte vibrante, piédestal gravé aux noms des Veilleurs.",
        objectives: [goTo("ea-salle-verte", "Entrer dans la Salle Verte")],
        dialogue: [
          say("narrateur", "La lumière est douce. Presque vivante. Elle respire.", "mysterieux"),
          say("maelle", "Je n'ai jamais rien vu d'aussi beau. Et d'aussi dangereux.", "inquiet"),
        ],
      }),
      part({
        id: "c24-p2", title: "Prendre l'émeraude", zone: "ea-salle-verte",
        summary: "Le joueur prend le Kalon-Glas. La salle tremble.",
        objectives: [collect("kalon-glas", 1, "Prendre le Kalon-Glas")],
        dialogue: [
          say("releve", "Rapporter l'émeraude au phare. Vite.", "solennel"),
          say("narrateur", "Au moment où votre main se referme, le sol gronde sous la citadelle.", "mysterieux"),
        ],
        rewards: { items: [{ item: "kalon-glas", count: 1 }], reputation: { veilleurs: 30 } },
        setFlags: ["kalon-glas-pris"],
      }),
      part({
        id: "c24-p3", title: "L'éveil", zone: "ea-crete-vents",
        summary: "Le Pic de Braise s'embrase. Un œil immense s'ouvre dans la lave.",
        cinematic: "Le cratère rougeoie. Plan serré sur une pupille verticale qui s'ouvre. Rugissement. Tremblement de caméra.",
        objectives: [goTo("ea-crete-vents", "Fuir sur la Crête des Vents")],
        dialogue: [
          say("aerouant", "Qui touche… à mon cœur ?", "colere"),
          say("goulven", "Il est réveillé ! Tous à la côte !", "colere"),
        ],
        journalEntry: "Fin de l'Acte IV. Le Kalon-Glas est en main. Aerouant est réveillé. Direction la côte, le bateau et le phare.",
        setFlags: ["dragon-reveille", "acte4-termine"],
      }),
    ],
  }),
];
