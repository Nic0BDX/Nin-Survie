# PROMPT À COLLER DANS L'AGENT DE CODE

Tu travailles sur mon jeu 3D low-poly d'aventure/survie situé dans l'archipel de Keravel (phare rouge et blanc, île avec prairie, crique, passes de marée, HUD Vie / Chaleur / Faim, ressources Bois / Silex / Rations, touches B = Construire et M = Carte, cycle jour/nuit, marée, cloche du phare, menu « Journal de relève »).

Je te donne un dossier `src/story/` **déjà écrit et validé en TypeScript strict**. Il contient tout le récit : 5 actes, 30 chapitres, 90 parties, le monde (53 zones, rivières), les personnages, les objets, les ennemis, le dragon en 4 phases et un moteur d'histoire (`StoryEngine`). Ton travail est de **l'intégrer au jeu et de construire tout ce qui manque pour le rendre jouable de bout en bout**.

## 0. Règles de travail

1. **Commence par lire le dépôt entier** (structure, moteur 3D, HUD, inventaire, système de carte, de construction, de marée, de sauvegarde). Je ne te donne pas le code ici : adapte-toi à l'existant, ne casse rien de ce qui marche, garde le style visuel low-poly actuel.
2. Copie `src/story/` dans le projet (adapte les chemins d'import si besoin) et lance `npx tsx src/story/validate.ts`. Il doit afficher « Validation OK » et simuler les 3 fins. **Ne modifie pas le contenu narratif** sans raison. Si tu ajoutes une zone, un objet ou un ennemi, ajoute-le aussi dans `world.ts` / `database.ts` pour que la validation reste verte.
3. Travaille **par étapes** (section 3). À la fin de chaque étape : le jeu compile, tourne, `validate.ts` est vert, tu fais un commit clair, et tu m'écris un court résumé de ce qui marche.
4. Le jeu doit rester **fluide** (low-poly, instanciation des arbres et rochers, LOD, chargement de zones par morceaux). Pas d'effets lourds inutiles.
5. Tout le texte affiché au joueur est **en français**.

## 1. Le récit en une page

La relève du Service des feux arrive à Keravel. Le phare est éteint depuis 3 ans : il manque 3 pièces (lentille au **Courlis**, réflecteur à la **Corne de brume**, dynamo aux **Salines**) et une **braise**. Cette braise est en réalité le **Kalon-Glas**, une émeraude-cœur qui endort le dragon **Aerouant** grâce à sa lumière verte. Elle a été volée par le **Baron Hoël de Kerhoël** de **Trois-Vannes** (le grand village) et cachée dans la **citadelle de Kastell-Glas**, sur la grande île extérieure **Enez-Aerouant**, protégée par la **Garde de l'Émeraude**. La relève traverse la Mer d'Iroise, survit sur l'île (rivière, forêt, marais, ruines), infiltre la citadelle, bat les gardes et le Baron, prend l'émeraude… ce qui réveille le dragon. Combat final contre Aerouant à Trois-Vannes puis au phare, avec **3 fins** (sceller / tuer / libérer).

Lis `RECIT.md` pour tout le détail chapitre par chapitre.

## 2. Ce que tu dois construire

### 2.1 Intégration du moteur d'histoire
- Instancie un `StoryEngine` au démarrage de la partie et branche ses callbacks sur l'UI du jeu.
- **Envoie les `GameEvent` depuis les systèmes existants** :
  | Système du jeu | Événement à émettre |
  |---|---|
  | Le joueur entre dans une zone (trigger) | `enter-zone` |
  | Ramassage / craft / récolte | `item-added`, `crafted` |
  | Construction (touche B) | `built` |
  | Interaction [E] sur un objet ou un mécanisme | `interacted` (id de la cible) |
  | Dialogue terminé avec un PNJ | `npc-talked` |
  | Mort d'un ennemi | `enemy-defeated` |
  | Cycle jour/nuit et marée | `time`, `tide` |
  | Temps passé sous une menace | `survived` (secondes) |
  | Énigmes / mini-jeux | `puzzle-solved` |
  | Passage furtif réussi | `sneaked` |
- **Journal de relève** : remplace/complète le panneau existant avec l'acte, le chapitre, la partie en cours, la liste des objectifs avec progression (`progressOf`), et le journal (`getJournal()`).
- **Carte (M)** : affiche l'archipel actuel + Trois-Vannes + Enez-Aerouant (débloquées via `unlockZones`), et la boussole qui suit l'objectif courant.
- **Système de dialogue** : boîte de dialogue avec nom, texte, humeur (`mood`), défilement, et UI de **choix** (`choices`) qui appelle `engine.choose(...)`.
- **Sauvegarde** : `engine.save()` / `engine.load()` branchés à la sauvegarde du jeu. Sauvegarde auto à chaque fin de partie (`onPartComplete`).
- Le phare a une **puissance de lampe** (`getLampPower()`) : 0 = éteint, 35 = lumière pâle (braise de fortune), 100 = faisceau vert du Kalon-Glas. Visuel et rayon de protection contre la brume selon la valeur.

### 2.2 Le monde (grande map)
Respecte les zones de `world.ts` (champ `links` = connexions, `access` = condition d'accès).

**A. L'archipel de Keravel (déjà là — à compléter)** : prairie du phare, crique, passes de marée vers Le Courlis (épave avec cale inondée), la Corne de brume (treuil à caler), l'Atelier des Salines (roue à eau + dynamo), Basse des Dents, Mer d'Iroise. Les passes ne sont praticables qu'à **marée basse**.

**B. Trois-Vannes, le grand village** : un vrai village vivant avec les 13 lieux de `world.ts` (remparts, place de la Cloche avec fontaine et grande cloche, auberge, forge, apothicairerie, chapelle avec caves, halle, criée, port, chantier naval, moulin à marée, manoir du Baron). PNJ avec routines jour/nuit, boutiques/échanges, panneau d'annonces, gardes du Baron en patrouille. C'est le **hub** de l'acte II et le champ de bataille du chapitre 27.

**C. Enez-Aerouant, la grande île extérieure (grande carte ouverte)** : 27 zones avec des biomes très différents, avec **la Stêr-Glas** (rivière verte qui descend du Lac Miroir, passe par la Cascade du Voile avec grotte secrète derrière la chute, un pont de corde, un gué, jusqu'au delta), la forêt sombre de Coat-Du, le marais de Stank, le village abandonné de Ker-Goz, les landes de Brug avec menhirs, les gorges de Roc'h-Gwenn, les ruines des Veilleurs, le camp de la Garde, les mines vertes, la citadelle de Kastell-Glas (remparts, cour d'armes, donjon de 6 étages, cryptes, salle verte), la crête des vents, le Pic de Braise (volcan) et l'antre du dragon. Un **grand terrain cohérent**, avec relief, chemins, points d'intérêt cachés, raccourcis, et les 3 **boîtes des veilleurs** (Corne de brume, Grotte du Voile, Ruines) comme collectibles.
La rivière doit être **une vraie rivière** : courant visible, gué traversable, pont de corde, cascade, possibilité de pêcher.

### 2.3 Gameplay à implémenter
- **Combat** : attaque, esquive/roulade, parade avec bouclier, tir à l'arbalète, harpon, barre de vie des ennemis et des boss. Les ennemis de `database.ts` (statistiques et comportements décrits dans `behavior` / `weakness`).
- **Furtivité** : champ de vision des gardes, bruit, uniforme volé (`uniforme-garde`), sorties d'alerte.
- **Gardes de l'émeraude** : recrues, lanciers, arbalétriers, boucliers, plus 3 boss de la citadelle (Maître d'armes, Capitaine Orwenn, Baron).
- **Survie** : Vie / Chaleur / Faim, feu de camp, abri, camp de base sur l'île, poison du marais et antidote.
- **Craft & forge** : recettes de `database.ts`, stations (établi, forge de Tangi, apothicairerie).
- **Bateau** : la *Veilleuse*, navigation en haute mer (Mer d'Iroise), vent, tempête (chapitre 13), poursuite du dragon avec harpons (chapitre 26).
- **Énigmes** : treuil de la Corne, roue des Salines, feux follets, leviers et miroirs du donjon, herse, concours de la Fête de la Cloche.
- **Brume et spectres** : la Brume arrive la nuit tant que la lampe est faible, la cloche sonne, les spectres fuient la lumière de la lanterne.

### 2.4 Le combat final contre Aerouant (le plus important)
Boss de 4000 PV en **4 phases** (voir `enemies` → `aerouant.phases` dans `database.ts`) :
1. **Le Ciel de Feu** (port de Trois-Vannes) : le dragon vole en rase-mottes et lâche des pluies de braises. Le joueur charge des **balistes** avec Yannig et les villageois et vise les ailes pour le faire atterrir. Cercles rouges au sol pour télégraphier les attaques.
2. **Le Dragon au Sol** (prairie du phare) : coup de queue, morsure, souffle de braise en cône. On se protège derrière rochers et barrière, on frappe le ventre exposé après chaque souffle.
3. **La Lumière Verte** (phare) : le joueur monte la tour, place le **Kalon-Glas** dans la lanterne (`lampPower = 100`), la zone s'illumine en vert.
4. **L'Agonie de Braise** : le joueur oriente le **faisceau vert** sur le dragon avec une séquence de timing pendant que la marée de braise recule.

À la fin, le **choix** (`fin-dragon`) déclenche l'une des 3 fins (`fin-veilleur`, `fin-chasseur`, `fin-liberation`) avec cinématique d'aube différente au chapitre 30. Le dragon doit être **énorme, lisible et spectaculaire** : animations d'ailes, de souffle, de rugissement, secousses d'écran, particules de braise, cendres dans le ciel.

### 2.5 Ambiance, audio, finition
- Cinématiques légères aux moments marqués `cinematic` (caméra scriptée, letterbox, fondu).
- Musique par région (archipel calme, village chaleureux, forêt/marais inquiétant, citadelle martiale, dragon épique), sons de mer, vent, cloche, forge.
- Menu pause, options, écran de fin avec la fin obtenue, **monde libre** après l'histoire (`monde-libre`).

## 3. Plan de travail (une étape = un commit)

1. **Fondations** : intégrer `src/story/`, `validate.ts` vert, `StoryEngine` + Journal de relève + dialogues + choix + sauvegarde. *Test :* je peux jouer le chapitre 1 avec ses 3 parties.
2. **Acte I complet** : chapitres 1 à 6 sur l'archipel (passes de marée, Courlis, Corne, Salines, allumage du phare, lampe à 35). *Test :* le phare s'allume faiblement et la lueur verte apparaît.
3. **Acte II : Trois-Vannes** : le grand village complet, PNJ, boutiques, forge, caves, manoir, fête, chantier, bateau. *Test :* je peux construire la Veilleuse et partir.
4. **Acte III : Enez-Aerouant (1/2)** : traversée, tempête, naufrage, plage, camp de base, Stêr-Glas (gué, pont, cascade, grotte), forêt, Cerf de Brume.
5. **Acte III (2/2)** : marais, Ker-Goz, Serpent, gorges, golem, ruines des Veilleurs, Erwan, clé de braise.
6. **Acte IV : la citadelle** : camp de la Garde (3 approches), mines, remparts, cour d'armes, 3 boss, donjon, Salle Verte, éveil du dragon.
7. **Acte V : le dragon** : fuite, poursuite en bateau, village sous le feu, combat en 4 phases, choix, 3 fins, épilogue, monde libre.
8. **Finition** : équilibrage, optimisation, bugs, audio, passe visuelle, test complet des 3 fins avec `simulate(...)` et en jeu.

## 4. Critères de réussite
- [ ] Partie jouable du chapitre 1 au chapitre 30 sans blocage.
- [ ] Les 3 fins fonctionnent et déclenchent des scènes différentes.
- [ ] Toutes les zones de `world.ts` existent dans le jeu et sont atteignables.
- [ ] Rivière réelle avec gué, pont de corde, cascade et grotte cachée.
- [ ] Combat de dragon en 4 phases complet.
- [ ] `npx tsx src/story/validate.ts` affiche « Validation OK » et les 3 simulations réussissent.
- [ ] Le jeu garde un framerate fluide sur un PC normal.

À la fin de chaque étape, donne-moi : ce qui est fait, comment le tester, et ce qui reste.
