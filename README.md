# Nin Survie · Keravel

Un jeu 3D d’aventure et de survie dans un archipel breton fantastique. La relève du Service des feux quitte Trois-Vannes pour rallumer le phare de Keravel. L’enquête sur la braise disparue la mène jusqu’à Enez-Aerouant.

[Version publique](https://nin-survie.vercel.app) · [Préproduction de la nouvelle carte](https://nin-survie-qcsemqkq7-nrx5.vercel.app)

## Le jeu

- Départ à **Trois-Vannes**. Le registre de la place de la Cloche ouvre le prologue, du port jusqu’au premier quart au phare.
- Survie avec Vie, Chaleur, Faim, récolte, construction, marées et cycle jour/nuit. Exploration à pied et en bateau.
- Atlas illustré de 53 repères et vue du relief. La Stêr-Glas relie le lac, la cascade, le pont de corde et le gué.
- Bâtiments procéduraux avec pans de bois, toits, tours, arches de pierre et façades civiques.
- Commandes clavier et souris, commandes tactiles en paysage et sauvegarde automatique.

## Installation et lancement

1. Installer **Godot 4.7.2** et télécharger le dépôt.
2. Importer `project.godot` dans le gestionnaire de projets.
3. Lancer le projet avec **F5**, puis choisir **Nouvelle traversée**.

Sur ordinateur, utiliser **ZQSD**, **WASD** ou les flèches pour se déplacer, **E** pour interagir, **B** pour construire, **M** pour la carte et **Échap** pour la pause. Sur téléphone, jouer en paysage avec le joystick et glisser à droite pour tourner la caméra.

L’export Web utilise Godot Compatibility et WebGL 2. Sur Linux, le script Vercel demande Node.js, Bash, curl et unzip, puis écrit `dist/index.html`.

```bash
bash build-web.sh
NIN_VERIFY=world bash build-web.sh
```

Pour valider les données du récit avec Node.js et npm.

```bash
cd story_authoring
npm install
npm run typecheck
npm run validate
```

## Architecture

| Fichiers | Rôle |
| --- | --- |
| `main.tscn`, `game.gd`, `hud.gd` | Boucle de jeu, interactions, sauvegarde et interface. |
| `biome.gd`, `keravel_map.gd`, `keravel_cartography.gd` | Terrain, liaisons et repères géographiques. |
| `keravel_architecture.gd`, `keravel_civic.gd`, `meshwork.gd` | Kit de bâtiments et génération de maillages. |
| `keravel_prologue.gd`, `keravel_story.json`, `story_authoring/` | Prologue Godot, données narratives et sources TypeScript. |
| `web-host.mjs`, `verify-web.mjs`, `vercel.json` | Version navigateur, tests mobiles et hébergement. |
| `studio/` | Orchestration, catalogue architectural, contrôles visuels et synchronisation Git. |

## Avancement

Le prologue couvre l’ordre de relève, la traversée, la cloche, les récoltes, la première nuit près du feu et le journal d’Erwan. L’expédition guide ensuite le joueur jusqu’au Kalon-Glas. Les 30 chapitres et les trois fins sont présents dans les données du récit. Les intérieurs, les dialogues et objectifs des chapitres suivants, les combats avancés et les trois fins jouables restent en développement.

Le contrôle Godot a exécuté 66 vérifications sans échec. La préproduction a aussi produit deux captures WebGL. [Trois-Vannes](https://nin-survie-qcsemqkq7-nrx5.vercel.app/studio-trois-vannes.jpg) · [Atlas](https://nin-survie-qcsemqkq7-nrx5.vercel.app/studio-atlas.jpg)

[Guide du studio autonome](AUTONOMOUS_SYSTEM.md) · [Mémoire du projet](PROJECT_MEMORY.md)
