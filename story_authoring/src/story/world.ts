import type { River, Zone } from "./types";

// ============================================================
//  1) L'ARCHIPEL DE KERAVEL (la base existante du jeu)
// ============================================================
const archipel: Zone[] = [
  {
    id: "ponton-arrivee", name: "Ponton de l'Arrivée", region: "archipel", biome: "côte",
    description: "Le ponton où la relève débarque. La cloche du phare résonne encore au loin.",
    links: ["prairie-phare"],
  },
  {
    id: "prairie-phare", name: "Prairie du Phare", region: "archipel", biome: "prairie",
    description: "Herbes hautes, fleurs, arbres low-poly, barrière de bois et sentier de terre vers le phare.",
    links: ["ponton-arrivee", "phare-keravel", "route-trois-vannes", "crique-baies", "passe-courlis", "passe-nord", "passe-salines"],
    points: ["tas de bois", "buisson de baies", "silex", "panneau directionnel"],
  },
  {
    id: "crique-baies", name: "Crique aux Baies", region: "archipel", biome: "plage",
    description: "Une crique de sable clair bordée de buissons de baies rouges.",
    links: ["prairie-phare"],
  },
  {
    id: "phare-keravel", name: "Phare de Keravel", region: "archipel", biome: "phare",
    description: "Tour rouge et blanche. La lanterne est éteinte : il manque 3 pièces et une braise.",
    links: ["prairie-phare"],
    points: ["porte du phare", "salle du journal", "escalier", "salle de la lanterne", "balcon"],
  },
  {
    id: "passe-courlis", name: "Passe du Courlis", region: "archipel", biome: "passe de marée",
    description: "Bande de sable praticable uniquement à marée basse.",
    links: ["prairie-phare", "le-courlis"], access: "maree-basse",
  },
  {
    id: "le-courlis", name: "Le Courlis", region: "archipel", biome: "épave",
    description: "Un vieux caboteur échoué sur un îlot ouest. La lentille est dans la cale.",
    links: ["passe-courlis"], points: ["cale inondée", "cabine du capitaine", "mât brisé"],
  },
  {
    id: "passe-nord", name: "Passe du Chenal du Nord", region: "archipel", biome: "passe de marée",
    description: "Les récifs affleurent, la passe ne se découvre qu'un court instant.",
    links: ["prairie-phare", "corne-de-brume"], access: "maree-basse",
  },
  {
    id: "corne-de-brume", name: "La Corne de Brume", region: "archipel", biome: "îlot rocheux",
    description: "Îlot nord, station de la corne de brume. Le réflecteur est sous le treuil.",
    links: ["passe-nord"], points: ["treuil", "cabane du sonneur", "boîte des veilleurs n°1"],
  },
  {
    id: "passe-salines", name: "Passe des Salines", region: "archipel", biome: "passe de marée",
    description: "Chemin de sel et de vase vers l'île nord-est.",
    links: ["prairie-phare", "ateliers-salines"], access: "maree-basse",
  },
  {
    id: "ateliers-salines", name: "L'Atelier des Salines", region: "archipel", biome: "marais salants",
    description: "Marais salants et atelier à roue à eau. La dynamo est coincée sous les décombres.",
    links: ["passe-salines"], points: ["roue à eau", "atelier", "bassins de sel"],
  },
  {
    id: "basse-des-dents", name: "Basse des Dents", region: "archipel", biome: "récif",
    description: "Récif en dents de scie qui a brisé plus d'un navire. Zone de brume.",
    links: ["mer-iroise"], access: "bateau",
  },
  {
    id: "mer-iroise", name: "Mer d'Iroise", region: "archipel", biome: "haute mer",
    description: "La mer ouverte entre Keravel et l'île du dragon. Courants, tempêtes, brume.",
    links: ["basse-des-dents", "tv-port", "ea-plage-naufrages"], access: "bateau",
  },
];

// ============================================================
//  2) TROIS-VANNES — le grand village (hub principal)
// ============================================================
const troisVannes: Zone[] = [
  {
    id: "route-trois-vannes", name: "Route de Trois-Vannes", region: "trois-vannes", biome: "chemin côtier",
    description: "Chemin de terre qui longe la côte du phare jusqu'au village.",
    links: ["prairie-phare", "tv-remparts"],
  },
  {
    id: "tv-remparts", name: "Les Remparts", region: "trois-vannes", biome: "village",
    description: "Murs de pierre sèche et porte principale du village. Les gardes du Baron surveillent.",
    links: ["route-trois-vannes", "tv-place-cloche", "tv-port"],
  },
  {
    id: "tv-place-cloche", name: "Place de la Cloche", region: "trois-vannes", biome: "village",
    description: "Cœur du village : fontaine, grande cloche de bronze, marché et panneau des annonces.",
    links: ["tv-remparts", "tv-auberge", "tv-forge", "tv-apothicaire", "tv-chapelle", "tv-halle", "tv-manoir", "tv-criee"],
  },
  {
    id: "tv-auberge", name: "Auberge du Goéland Rouge", region: "trois-vannes", biome: "intérieur",
    description: "Chambres, cheminée, rumeurs. Yannig y sert les tables.",
    links: ["tv-place-cloche"],
  },
  {
    id: "tv-forge", name: "Forge de Tangi", region: "trois-vannes", biome: "intérieur",
    description: "Enclume, soufflet, armes et outils. Craft avancé.",
    links: ["tv-place-cloche"],
  },
  {
    id: "tv-apothicaire", name: "Apothicairerie de Nolwenn", region: "trois-vannes", biome: "intérieur",
    description: "Herbes séchées, onguents, antidotes.",
    links: ["tv-place-cloche"],
  },
  {
    id: "tv-chapelle", name: "Chapelle Sainte-Azenor", region: "trois-vannes", biome: "chapelle",
    description: "Petite chapelle de granit. Une trappe mène aux caves aux fresques.",
    links: ["tv-place-cloche", "tv-caves"],
  },
  {
    id: "tv-caves", name: "Les Caves aux Fresques", region: "trois-vannes", biome: "souterrain",
    description: "Fresques anciennes : un dragon endormi, une émeraude, un phare.",
    links: ["tv-chapelle"], access: "cle",
  },
  {
    id: "tv-halle", name: "La Halle aux Grains", region: "trois-vannes", biome: "village",
    description: "Marché couvert, échanges de ressources, concours de la Fête de la Cloche.",
    links: ["tv-place-cloche"],
  },
  {
    id: "tv-criee", name: "La Criée", region: "trois-vannes", biome: "port",
    description: "Marché au poisson, rations, rumeurs de marins.",
    links: ["tv-place-cloche", "tv-port"],
  },
  {
    id: "tv-port", name: "Le Port de Trois-Vannes", region: "trois-vannes", biome: "port",
    description: "Quais, barques, balises. Départ vers la Mer d'Iroise.",
    links: ["tv-remparts", "tv-criee", "tv-chantier", "tv-moulin", "mer-iroise"],
  },
  {
    id: "tv-chantier", name: "Chantier naval de Corentin", region: "trois-vannes", biome: "port",
    description: "Cale sèche où l'on construit le bateau pour la traversée.",
    links: ["tv-port"],
  },
  {
    id: "tv-moulin", name: "Moulin à marée", region: "trois-vannes", biome: "village",
    description: "Moulin dont la roue tourne avec la marée. Idéal pour une cache secrète.",
    links: ["tv-port"],
  },
  {
    id: "tv-manoir", name: "Manoir Kerhoël", region: "trois-vannes", biome: "manoir",
    description: "Demeure du Baron Hoël de Kerhoël : salle à manger, bureau, cave aux coffres.",
    links: ["tv-place-cloche"], access: "cle",
    points: ["salle à manger", "bureau du Baron", "coffre vide", "registres de cargaison"],
  },
];

// ============================================================
//  3) ENEZ-AEROUANT — la grande île extérieure (rivière, forêt, marais…)
// ============================================================
const enezAerouant: Zone[] = [
  {
    id: "ea-plage-naufrages", name: "Plage des Naufragés", region: "enez-aerouant", biome: "plage",
    description: "Sable noir, épaves et débris. Premier contact avec l'île.",
    links: ["mer-iroise", "ea-embouchure", "ea-sentier-embruns"], access: "bateau",
  },
  {
    id: "ea-sentier-embruns", name: "Sentier des Embruns", region: "enez-aerouant", biome: "falaise",
    description: "Sentier de falaise battu par le vent, patrouilles de la Garde.",
    links: ["ea-plage-naufrages", "ea-camp-base", "ea-foret-coat-du"],
  },
  {
    id: "ea-camp-base", name: "Camp de Base des Naufragés", region: "enez-aerouant", biome: "camp",
    description: "Abri, feu et établi construits par le joueur. Point de sauvegarde et de craft.",
    links: ["ea-sentier-embruns", "ea-embouchure"],
  },
  {
    id: "ea-embouchure", name: "Embouchure de la Stêr-Glas", region: "enez-aerouant", biome: "delta",
    description: "La grande rivière verte se jette dans la mer en un delta de roseaux.",
    links: ["ea-plage-naufrages", "ea-camp-base", "ea-gue-lavandieres"],
  },
  {
    id: "ea-gue-lavandieres", name: "Gué des Lavandières", region: "enez-aerouant", biome: "rivière",
    description: "Gué peu profond, pierres plates, vieux lavoirs.",
    links: ["ea-embouchure", "ea-pont-de-corde", "ea-foret-coat-du"], access: "gue",
  },
  {
    id: "ea-pont-de-corde", name: "Pont de Corde de Pen-Stêr", region: "enez-aerouant", biome: "rivière",
    description: "Pont suspendu au-dessus des rapides. Surveillé par la Garde.",
    links: ["ea-gue-lavandieres", "ea-cascade-voile"], access: "pont",
  },
  {
    id: "ea-cascade-voile", name: "Cascade du Voile", region: "enez-aerouant", biome: "cascade",
    description: "Chute d'eau haute de vingt mètres. Une grotte secrète se cache derrière le rideau d'eau.",
    links: ["ea-pont-de-corde", "ea-lac-miroir", "ea-grotte-voile"],
  },
  {
    id: "ea-grotte-voile", name: "Grotte du Voile", region: "enez-aerouant", biome: "grotte",
    description: "Grotte cachée derrière la cascade. Contient la boîte des veilleurs n°2.",
    links: ["ea-cascade-voile"], points: ["boîte des veilleurs n°2"],
  },
  {
    id: "ea-lac-miroir", name: "Lac Miroir", region: "enez-aerouant", biome: "lac",
    description: "Source de la Stêr-Glas. Eau immobile qui reflète le Pic de Braise.",
    links: ["ea-cascade-voile", "ea-landes-brug"],
  },
  {
    id: "ea-foret-coat-du", name: "Forêt de Coat-Du", region: "enez-aerouant", biome: "forêt sombre",
    description: "Forêt dense et humide. Feux follets, loups, silence pesant.",
    links: ["ea-sentier-embruns", "ea-gue-lavandieres", "ea-coeur-foret", "ea-marais-stank"],
  },
  {
    id: "ea-coeur-foret", name: "Cœur de la Forêt", region: "enez-aerouant", biome: "clairière",
    description: "Clairière du Cerf de Brume, gardien de la forêt.",
    links: ["ea-foret-coat-du"],
  },
  {
    id: "ea-marais-stank", name: "Marais de Stank", region: "enez-aerouant", biome: "marais",
    description: "Marais brumeux, eaux stagnantes, plantes toxiques, ponts de planches pourris.",
    links: ["ea-foret-coat-du", "ea-ker-goz", "ea-antre-serpent"],
  },
  {
    id: "ea-antre-serpent", name: "Antre du Serpent de Stank", region: "enez-aerouant", biome: "marais",
    description: "Île de vase au cœur du marais. Repaire du Serpent.",
    links: ["ea-marais-stank"],
  },
  {
    id: "ea-ker-goz", name: "Ker-Goz, le Vieux Village", region: "enez-aerouant", biome: "village abandonné",
    description: "Village de pêcheurs vidé par la Garde. Quelques survivants se cachent.",
    links: ["ea-marais-stank", "ea-landes-brug"],
  },
  {
    id: "ea-landes-brug", name: "Landes de Brug", region: "enez-aerouant", biome: "landes",
    description: "Bruyère violette, vent fort, menhirs. Le Pic de Braise domine l'horizon.",
    links: ["ea-ker-goz", "ea-lac-miroir", "ea-gorges-rochgwenn", "ea-camp-garde"],
  },
  {
    id: "ea-gorges-rochgwenn", name: "Gorges de Roc'h-Gwenn", region: "enez-aerouant", biome: "gorges",
    description: "Falaises blanches, passerelles, éboulis. Gardées par un golem de schiste.",
    links: ["ea-landes-brug", "ea-ruines-veilleurs"],
  },
  {
    id: "ea-ruines-veilleurs", name: "Ruines des Veilleurs", region: "enez-aerouant", biome: "ruines",
    description: "Ancien phare effondré où vivaient les premiers Veilleurs.",
    links: ["ea-gorges-rochgwenn"], points: ["tour effondrée", "bibliothèque", "boîte des veilleurs n°3"],
  },
  {
    id: "ea-camp-garde", name: "Camp de la Garde de l'Émeraude", region: "enez-aerouant", biome: "camp militaire",
    description: "Tentes, palissades, tours de guet. Point d'entrée vers les mines et la citadelle.",
    links: ["ea-landes-brug", "ea-mines-vertes", "ea-citadelle-remparts"],
  },
  {
    id: "ea-mines-vertes", name: "Les Mines Vertes", region: "enez-aerouant", biome: "mines",
    description: "Galeries où les villageois sont forcés de miner la poussière d'émeraude.",
    links: ["ea-camp-garde", "ea-citadelle-cryptes"],
  },
  {
    id: "ea-citadelle-remparts", name: "Remparts de Kastell-Glas", region: "enez-aerouant", biome: "citadelle",
    description: "Hautes murailles vertes, herse, chemins de ronde.",
    links: ["ea-camp-garde", "ea-citadelle-cour"],
  },
  {
    id: "ea-citadelle-cour", name: "Cour d'Armes", region: "enez-aerouant", biome: "citadelle",
    description: "Grande cour pavée où s'entraîne la Garde.",
    links: ["ea-citadelle-remparts", "ea-citadelle-donjon"],
  },
  {
    id: "ea-citadelle-cryptes", name: "Cryptes de Kastell-Glas", region: "enez-aerouant", biome: "souterrain",
    description: "Passage secret reliant les mines au donjon.",
    links: ["ea-mines-vertes", "ea-citadelle-donjon"],
  },
  {
    id: "ea-citadelle-donjon", name: "Donjon du Baron", region: "enez-aerouant", biome: "citadelle",
    description: "Tour de six étages. Tout en haut : la salle verte et le piédestal du Kalon-Glas.",
    links: ["ea-citadelle-cour", "ea-citadelle-cryptes", "ea-salle-verte"],
  },
  {
    id: "ea-salle-verte", name: "La Salle Verte", region: "enez-aerouant", biome: "salle du trésor",
    description: "Salle ronde baignée de lumière verte. Piédestal du Kalon-Glas.",
    links: ["ea-citadelle-donjon", "ea-crete-vents"],
  },
  {
    id: "ea-crete-vents", name: "Crête des Vents", region: "enez-aerouant", biome: "montagne",
    description: "Crête étroite entre la citadelle et le cratère. Le sol tremble.",
    links: ["ea-salle-verte", "ea-pic-braise", "ea-plage-naufrages"],
  },
  {
    id: "ea-pic-braise", name: "Pic de Braise", region: "enez-aerouant", biome: "volcan",
    description: "Volcan endormi dont le cratère abrite l'antre d'Aerouant.",
    links: ["ea-crete-vents", "ea-antre-aerouant"],
  },
  {
    id: "ea-antre-aerouant", name: "Antre d'Aerouant", region: "enez-aerouant", biome: "caverne de lave",
    description: "Caverne immense, lac de braise, ossements de navires. Le dragon dort ici.",
    links: ["ea-pic-braise"],
  },
];

export const zones: Zone[] = [...archipel, ...troisVannes, ...enezAerouant];
export const zoneById = (id: string): Zone | undefined => zones.find((z) => z.id === id);

// ============================================================
//  RIVIÈRES
// ============================================================
export const rivers: River[] = [
  {
    id: "ster-glas",
    name: "La Stêr-Glas (la Rivière Verte)",
    source: "ea-lac-miroir",
    mouth: "ea-embouchure",
    course: ["ea-lac-miroir", "ea-cascade-voile", "ea-pont-de-corde", "ea-gue-lavandieres", "ea-embouchure"],
    crossings: [
      { zone: "ea-gue-lavandieres", kind: "gue" },
      { zone: "ea-pont-de-corde", kind: "pont-de-corde" },
      { zone: "ea-cascade-voile", kind: "cascade" },
    ],
  },
  {
    id: "ruisseau-stank",
    name: "Le Ruisseau de Stank",
    source: "ea-foret-coat-du",
    mouth: "ea-marais-stank",
    course: ["ea-foret-coat-du", "ea-marais-stank"],
    crossings: [{ zone: "ea-marais-stank", kind: "barque" }],
  },
];
