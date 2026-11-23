# Mémoire compacte

- **État** — Godot 4.7.2, WebGL 2 Compatibility. Projet Nin Survie, archipel de Keravel. Pour la configuration et les limites du studio, voir `AUTONOMOUS_SYSTEM.md`.
- **Carte** — 53 lieux. Référence fournie par le joueur dans `keravel_atlas.jpg`, repères dans `keravel_cartography.gd`. Relief jouable et collisions dans `keravel_map.gd`. Enez-Aerouant à l’est.
- **Architecture** — `keravel_architecture.gd` mutualise toits, fenêtres, arches, tours et étals. La façade de la chapelle est intégrée via `keravel_civic.gd`. Le prochain travail sur ce bâtiment concerne son intérieur. Le catalogue et les preuves sont dans `studio/architecture/`.
- **Récit** — TypeScript source dans `story_authoring/`, données exportées dans `keravel_story.json`. Prologue Godot dans `keravel_prologue.gd`. L’expédition est guidée. Les systèmes de combat avancé et les trois fins jouables restent à intégrer.
- **Tests** — 66 checks Godot et deux captures WebGL réussis en préproduction. Dix tests Node pour budget, orchestration et synchronisation locale. Les simulations TypeScript et les validations Godot sont suivies séparément.
- **Reprise** — Consulter `studio/tasks.json`, les rapports de la dernière exécution et les différences Git des fichiers attribués. Revalider les conclusions seulement lorsque leurs entrées ont changé.
