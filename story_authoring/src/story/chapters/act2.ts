import { build, chapter, collect, craft, deliver, goTo, interact, part, say, sneak, solve, survive, talk } from "../helpers";

// ============================================================
//  ACTE II — TROIS-VANNES   (le grand village, hub principal)
//  Chapitres 7 à 12 · 18 parties
// ============================================================

export const act2 = [
  // ---------------------------------------------------------- CH 7
  chapter({
    id: "c07", number: 7, act: 2, title: "Les Portes de Trois-Vannes",
    synopsis: "Le village est grand, vivant, et méfiant. La relève doit se faire accepter.",
    parts: [
      part({
        id: "c07-p1", title: "La route côtière", zone: "route-trois-vannes",
        summary: "Une route de terre, des mouettes, une patrouille du Baron à éviter ou à saluer.",
        objectives: [goTo("tv-remparts", "Atteindre les remparts")],
        dialogue: [
          say("narrateur", "Au bout de la route, des toits d'ardoise et une cloche de bronze.", "neutre"),
          say("releve", "Enfin des gens.", "joyeux"),
        ],
      }),
      part({
        id: "c07-p2", title: "Place de la Cloche", zone: "tv-place-cloche",
        summary: "La doyenne Soizic accueille la relève, mais les villageois chuchotent.",
        objectives: [goTo("tv-place-cloche", "Traverser la place"), talk("soizic", "Parler à Soizic")],
        dialogue: [
          say("soizic", "Le Service des feux envoie une relève ? Après trois ans de silence ?", "inquiet"),
          say("releve", "J'ai rallumé le phare. Faiblement, mais il brille.", "neutre"),
          say("soizic", "On l'a vu. Les enfants ont applaudi. Les gardes du Baron, beaucoup moins.", "mysterieux"),
        ],
        setFlags: ["soizic-rencontree"],
        rewards: { unlockZones: ["tv-place-cloche", "tv-auberge", "tv-forge", "tv-apothicaire", "tv-halle", "tv-criee", "tv-port"] },
      }),
      part({
        id: "c07-p3", title: "Un lit à l'auberge", zone: "tv-auberge",
        summary: "Yannig, garçon d'auberge, prend la relève sous son aile et connaît tous les secrets du village.",
        objectives: [goTo("tv-auberge", "Entrer à l'auberge"), talk("yannig", "Parler à Yannig")],
        dialogue: [
          say("yannig", "Vous êtes la relève du phare ? Alors vous ne payez pas la soupe. Règle de la maison.", "joyeux"),
          say("yannig", "Mais un conseil : ne dites pas « émeraude » devant le Baron.", "inquiet"),
          say("releve", "Pourquoi cette émeraude ?", "mysterieux"),
          say("yannig", "Parce que tout le monde sait… mais personne ne dit.", "mysterieux"),
        ],
        setFlags: ["yannig-rencontre"],
      }),
    ],
  }),

  // ---------------------------------------------------------- CH 8
  chapter({
    id: "c08", number: 8, act: 2, title: "Gagner la Confiance",
    synopsis: "Petits services, grande forge : la relève s'intègre en rendant service.",
    parts: [
      part({
        id: "c08-p1", title: "L'apothicaire", zone: "tv-apothicaire",
        summary: "Nolwenn a besoin d'herbes de la côte pour soigner les enfants malades de la Brume.",
        objectives: [talk("nolwenn", "Parler à Nolwenn"), collect("baies", 6, "Rapporter 6 baies"), deliver("baies", "nolwenn", "Livrer les baies")],
        dialogue: [
          say("nolwenn", "La Brume donne la toux aux petits. Mes onguents ne suffisent plus.", "inquiet"),
          say("nolwenn", "Des baies de la crique, et je te prépare une petite fiole. Marché ?", "joyeux"),
        ],
        rewards: { items: [{ item: "rations", count: 3 }], reputation: { "trois-vannes": 10 } },
      }),
      part({
        id: "c08-p2", title: "La forge de Tangi", zone: "tv-forge",
        summary: "Tangi forge si on lui apporte du fer. La relève l'aide à réparer ses soufflets.",
        objectives: [talk("tangi", "Parler à Tangi"), collect("fer", 3, "Trouver 3 fers"), craft("epee-fer", "Forger une épée de fer")],
        dialogue: [
          say("tangi", "Tu cherches une lame ? Apporte le fer, je forge. Pas de cadeaux, ici.", "neutre"),
          say("tangi", "Les gardes du Baron achètent tout mon acier. Il en fait quoi ? Je préfère pas savoir.", "colere"),
        ],
        rewards: { items: [{ item: "epee-fer", count: 1 }], unlockRecipes: ["r-epee", "r-bouclier", "r-arbalete", "r-harpon"], reputation: { "trois-vannes": 10 } },
      }),
      part({
        id: "c08-p3", title: "La Criée", zone: "tv-criee",
        summary: "À la criée, une cartographe cherche quelqu'un pour affronter la mer.",
        objectives: [goTo("tv-criee", "Aller à la criée"), talk("maelle", "Parler à Maëlle")],
        dialogue: [
          say("maelle", "Tu as rallumé le phare ? Alors tu as vu la lueur verte à l'ouest.", "joyeux"),
          say("maelle", "Je dessine ses courants depuis deux ans. Il me manque un bateau. Et du courage.", "mysterieux"),
        ],
        setFlags: ["maelle-rencontree"],
        rewards: { reputation: { "trois-vannes": 5 } },
      }),
    ],
  }),

  // ---------------------------------------------------------- CH 9
  chapter({
    id: "c09", number: 9, act: 2, title: "La Chapelle et la Légende",
    synopsis: "Sous la chapelle Sainte-Azenor, des fresques racontent l'histoire du dragon et de l'émeraude.",
    parts: [
      part({
        id: "c09-p1", title: "Sœur Azenor", zone: "tv-chapelle",
        summary: "La gardienne de la chapelle teste la relève avant de lui confier la clé des caves.",
        objectives: [goTo("tv-chapelle", "Entrer dans la chapelle"), talk("azenor", "Parler à Sœur Azenor")],
        dialogue: [
          say("azenor", "Beaucoup cherchent l'émeraude. Peu cherchent pourquoi elle existe.", "mysterieux"),
          say("azenor", "Apporte-moi un cierge de bois d'épave, et je te laisse descendre.", "neutre"),
        ],
      }),
      part({
        id: "c09-p2", title: "Les caves aux fresques", zone: "tv-caves",
        summary: "Trois fresques : le dragon endormi, l'émeraude dans la lanterne, l'émeraude arrachée.",
        objectives: [collect("bois", 2, "Rapporter du bois d'épave"), goTo("tv-caves", "Descendre dans les caves"), interact("fresques", "Examiner les trois fresques")],
        dialogue: [
          say("azenor", "Première fresque : Aerouant dort. Deuxième : les Veilleurs placent le Kalon-Glas dans le phare.", "solennel"),
          say("azenor", "Troisième : la lumière verte quitte la lanterne. Et tout recommence.", "triste"),
          say("releve", "Donc la braise manquante, c'est l'émeraude.", "inquiet"),
        ],
        journalEntry: "Le Kalon-Glas, émeraude verte, était le cœur du phare. Sa lumière endort le dragon Aerouant. On l'a volée.",
        setFlags: ["legende-apprise", "kalon-glas-identifie"],
        rewards: { items: [{ item: "cle-caves", count: 1 }] },
      }),
      part({
        id: "c09-p3", title: "La prophétie des veilleurs", zone: "tv-caves",
        summary: "Une inscription annonce trois boîtes cachées contenant la vérité des premiers Veilleurs.",
        objectives: [interact("inscription-veilleurs", "Lire l'inscription")],
        dialogue: [
          say("azenor", "« Trois boîtes, trois souvenirs. Qui les réunit comprendra pourquoi on a enfermé le feu. »", "solennel"),
          say("releve", "J'en ai déjà trouvé une, sur la Corne de brume.", "joyeux"),
          say("azenor", "Alors tu es plus avancé que le Baron.", "mysterieux"),
        ],
        setFlags: ["prophetie-veilleurs"],
      }),
    ],
  }),

  // ---------------------------------------------------------- CH 10
  chapter({
    id: "c10", number: 10, act: 2, title: "Le Manoir Kerhoël",
    synopsis: "Le Baron invite la relève à dîner. Derrière les sourires, un coffre vide et des registres à fouiller.",
    parts: [
      part({
        id: "c10-p1", title: "L'invitation", zone: "tv-place-cloche",
        summary: "Un messager du Baron remet une invitation scellée de cire verte.",
        objectives: [interact("invitation-baron", "Recevoir l'invitation"), goTo("tv-manoir", "Se rendre au manoir")],
        dialogue: [
          say("narrateur", "La cire est verte, couleur d'émeraude.", "mysterieux"),
          say("soizic", "N'y va pas seul. Et ne bois pas son vin.", "inquiet"),
        ],
      }),
      part({
        id: "c10-p2", title: "Dîner de dupes", zone: "tv-manoir",
        summary: "Dialogue à choix avec le Baron. Chaque réponse change son attitude.",
        objectives: [talk("kerhoel", "Dîner avec le Baron")],
        dialogue: [
          say("kerhoel", "Ah, notre petite relève ! Votre phare nous rend la vie plus douce.", "joyeux"),
          say("kerhoel", "Dites-moi, que cherchez-vous à Keravel, exactement ?", "mysterieux"),
          say("releve", "Une braise.", "neutre"),
          say("kerhoel", "Une braise ! Quelle poésie. Hélas, je ne connais que du charbon.", "joyeux"),
        ],
        choices: [{
          id: "diner-baron", prompt: "Comment répondre au Baron ?",
          options: [
            { id: "franc", label: "Lui parler franchement de l'émeraude", setFlags: ["baron-alerte"], reputation: { "trois-vannes": 5 }, consequence: "Le Baron renforce la garde de son coffre." },
            { id: "prudent", label: "Rester vague et observer", setFlags: ["baron-endormi"], consequence: "Le Baron se croit en sécurité, plus facile à surprendre." },
            { id: "piege", label: "Glisser un faux indice pour le piéger", setFlags: ["baron-piege"], reputation: { veilleurs: 5 }, consequence: "Il enverra un messager à l'île, ce qui permet de le suivre." },
          ],
        }],
        setFlags: ["diner-fait"],
      }),
      part({
        id: "c10-p3", title: "Le coffre vide", zone: "tv-manoir",
        summary: "La nuit, infiltration dans le bureau : le coffre est vide, mais les registres de cargaison parlent.",
        objectives: [sneak("tv-manoir", "S'infiltrer dans le bureau"), interact("registres-cargaison", "Lire les registres"), interact("coffre-vide", "Examiner le coffre vide")],
        dialogue: [
          say("narrateur", "Le coffre est vide, mais la poussière de verre vert tapisse le fond.", "mysterieux"),
          say("releve", "Cargaisons vers Enez-Aerouant, une fois par mois. Chargées de fer, de vivres, d'hommes.", "inquiet"),
          say("releve", "Il a transféré l'émeraude là-bas. Dans une citadelle.", "colere"),
        ],
        journalEntry: "Le Baron a déplacé le Kalon-Glas sur Enez-Aerouant, dans la citadelle de Kastell-Glas, protégée par la Garde de l'Émeraude.",
        setFlags: ["preuve-baron", "citadelle-localisee"],
        rewards: { items: [{ item: "uniforme-garde", count: 1 }] },
      }),
    ],
  }),

  // ---------------------------------------------------------- CH 11
  chapter({
    id: "c11", number: 11, act: 2, title: "La Fête de la Cloche",
    synopsis: "Le village fête sa cloche. Concours, musique, et un sabotage qui change tout.",
    parts: [
      part({
        id: "c11-p1", title: "Préparatifs", zone: "tv-place-cloche",
        summary: "Guirlandes, lanternes, pains tressés : le village se prépare.",
        objectives: [collect("bois", 8, "Fournir du bois pour les feux"), interact("guirlandes", "Accrocher les lanternes")],
        dialogue: [
          say("yannig", "La fête, c'est la seule nuit où la Brume n'ose pas venir.", "joyeux"),
          say("soizic", "Alors faisons-la belle. Ils s'en souviendront.", "solennel"),
        ],
      }),
      part({
        id: "c11-p2", title: "Les concours", zone: "tv-halle",
        summary: "Mini-jeux : course à la rame, tir à l'arbalète, course aux lanternes. Gagner donne du soutien et du matériel.",
        objectives: [solve("concours-rame", "Gagner la course à la rame"), solve("concours-tir", "Réussir le tir à l'arbalète"), solve("concours-lanternes", "Terminer la course aux lanternes", )],
        dialogue: [
          say("tangi", "T'as du bras. Garde-le pour plus tard.", "joyeux"),
          say("maelle", "La rame, c'est de la navigation déguisée. Retiens bien le rythme.", "joyeux"),
        ],
        rewards: { reputation: { "trois-vannes": 15 }, items: [{ item: "arbalete", count: 1 }] },
        setFlags: ["fete-concours-gagnes"],
      }),
      part({
        id: "c11-p3", title: "Le sabotage", zone: "tv-chantier",
        summary: "Pendant la fête, des hommes du Baron incendient le chantier naval pour empêcher toute traversée.",
        objectives: [goTo("tv-chantier", "Courir au chantier"), survive(40, "Éteindre l'incendie"), talk("corentin", "Parler à Corentin")],
        dialogue: [
          say("corentin", "Ma coque ! Ma belle coque !", "triste"),
          say("yannig", "Ce sont les gardes du Baron. J'ai vu leurs bottes vertes.", "colere"),
          say("soizic", "Il a peur de toi. C'est bon signe.", "solennel"),
        ],
        setFlags: ["chantier-sabote", "baron-hostile"],
      }),
    ],
  }),

  // ---------------------------------------------------------- CH 12
  chapter({
    id: "c12", number: 12, act: 2, title: "Le Bateau",
    synopsis: "Tout le village se mobilise pour construire un bateau capable de traverser la Mer d'Iroise.",
    parts: [
      part({
        id: "c12-p1", title: "Les plans de Corentin", zone: "tv-chantier",
        summary: "Corentin sauve ses plans et conçoit un petit navire robuste.",
        objectives: [talk("corentin", "Valider les plans"), interact("plans-bateau", "Étudier les plans")],
        dialogue: [
          say("corentin", "Une coque étroite, un mât unique, une voile de renfort. Il tiendra Iroise. Peut-être.", "neutre"),
          say("goulven", "Il tiendra. Je le conduirai.", "solennel"),
        ],
      }),
      part({
        id: "c12-p2", title: "Rassembler les matériaux", zone: "tv-port",
        summary: "Planches, fer, toile, sel : chaque métier du village contribue.",
        objectives: [collect("planche", 8, "8 planches"), collect("fer", 4, "4 lingots de fer"), collect("toile", 2, "2 toiles de voile"), collect("sel", 3, "3 sels gris")],
        dialogue: [
          say("tangi", "Du fer pour les gonds. Je ne laisse pas ma ville partir sans clous.", "neutre"),
          say("nolwenn", "Du sel pour conserver les vivres. Et un peu de courage en bouteille.", "joyeux"),
        ],
        rewards: { reputation: { "trois-vannes": 10 } },
      }),
      part({
        id: "c12-p3", title: "Le lancement", zone: "tv-port",
        summary: "Le bateau est mis à l'eau, baptisé, et l'équipage se forme.",
        objectives: [build("bateau-keravel", "Construire le bateau"), talk("maelle", "Embarquer Maëlle"), talk("goulven", "Embarquer Goulven")],
        dialogue: [
          say("soizic", "Que la mer te rende ce qu'elle nous a pris. Nomme-le.", "solennel"),
          say("releve", "La Veilleuse.", "joyeux"),
          say("yannig", "Rapporte-moi un coquillage brillant !", "joyeux"),
        ],
        journalEntry: "Fin de l'Acte II. La Veilleuse est lancée. Direction Enez-Aerouant, l'île du dragon.",
        setFlags: ["acte2-termine", "bateau-pret"],
        rewards: { unlockZones: ["mer-iroise", "ea-plage-naufrages"], items: [{ item: "carte-enez", count: 1 }, { item: "harpon", count: 1 }] },
      }),
    ],
  }),
];
