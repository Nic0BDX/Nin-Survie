# Mémoire du projet Nin Survie

## Vision

Aventure de survie en français dans un archipel breton fantastique. Le joueur part de Trois-Vannes, rallume le phare, traverse la Mer d’Iroise, explore Enez-Aerouant et retrouve le Kalon-Glas. La référence de la carte vient du joueur. `keravel_atlas.jpg` en conserve le cadrage et les dimensions natives.

## Architecture et décisions

- Godot 4.7.2, GDScript, moteur Compatibility pour Windows et WebGL. Terrain et bâtiments construits avec le mesh builder de `meshwork.gd`, collisions simplifiées et séparées du maillage visuel.
- `biome.gd` conserve les îlots, les passes et les systèmes de survie. `keravel_map.gd` étend la carte avec Trois-Vannes et Enez-Aerouant. Les coordonnées des anciennes sauvegardes de la préproduction sont migrées vers l’île à l’est.
- `keravel_architecture.gd` fournit les éléments de façade, toits détaillés, arches, tours et étals. Les détails les plus fins sont concentrés près du joueur et sur les monuments dans le profil mobile.
- Le prologue utilise les ressources, le feu, la chaleur et la sauvegarde existants. Les répliques du ponton, de la prairie et du journal viennent du scénario TypeScript. `keravel_story.json` expose 53 zones et 30 chapitres au moteur.
- Vercel construit la version Web avec `build-web.sh`. Les tests navigateur ont une préproduction dédiée. Le rendu mobile suit la zone visible du navigateur et utilise les marges de sécurité pour l’interface.

## Contrôles et problèmes connus

- La préproduction précédente a validé le départ, la carte et les interactions tactiles. Refaire les contrôles du monde après une modification de la géographie ou du prologue.
- Les modèles et ouvrages entrent dans le catalogue après inspection. Les intérieurs, le mobilier et l’éclairage des bâtiments patrimoniaux exigent des preuves distinctes.
- Le ZIP de production Godot peut compiler sans lancer de scène. Utiliser le test moteur `studio/check_world.gd` pour le trajet, les interactions et la sauvegarde. Les captures graphiques nécessitent un moteur avec affichage.
- Windows peut refuser l’exécution d’un binaire de test local. L’éditeur Linux utilisé lors du build Vercel permet le contrôle headless. Les validations Safari sur matériel restent à faire.
- La CLI Codex est installée sur Windows. La création de sessions autonomes dépend de l’authentification et de la capacité du processus local à accéder au profil utilisateur. Une session terminée ne travaille plus.

## Prochaines étapes

1. P1 — Relier les étapes suivantes du récit aux dialogues et événements du monde.
2. P2 — Construire et contrôler les intérieurs de l’auberge, de la forge et de la chapelle.
3. P2 — Donner plus de personnalité aux quartiers, placer des habitants et varier les parcours.
4. P1 — Intégrer le combat d’Aerouant et les trois fins jouables.
5. P4 — Établir des références de temps de chargement, rendu et mémoire sur plusieurs profils.

La file active, les dossiers attribués et leurs critères de contrôle sont dans `studio/tasks.json`.
