# Studio autonome de Keravel

Le superviseur Node lit `studio/tasks.json`, classe les missions de P0 à P4, lance une CLI Codex locale et vérifie les fichiers et les tests attribués. Chaque agent travaille dans un worktree Git issu d’un instantané local. Le directeur contrôle les correctifs avant de les intégrer au dépôt de développement. Les validations arrivent dans la branche privée du cycle.

## Commandes

```powershell
node studio/studio.mjs start --workers 2 --minutes 60
node studio/studio.mjs start --night --workers 2 --minutes 360 --task-minutes 35
node studio/studio.mjs status
node studio/studio.mjs pause
node studio/studio.mjs resume
node studio/studio.mjs stop
node studio/studio.mjs report
node studio/studio.mjs recover
```

**Pause** termine les missions en cours et suspend les suivantes. **Stop** conserve les worktrees au terme du cycle. **Recover** rapproche checkpoints et processus vérifiables. **Resume** reprend les réglages du cycle sauf surcharge explicite.

Les options sont `--workers`, `--minutes`, `--task-minutes`, `--attempts`, `--snapshot-mb`, `--codex <chemin absolu>` et `--night`. Le mode **ÉCO** est le défaut. Les options `--mode eco|normal|max`, `--task-tokens`, `--agent-tokens`, `--cycle-tokens` et `--night-tokens` ajustent la distribution. [Budget de tokens](TOKEN_BUDGET.md)

## Travail prolongé

Utiliser un poste avec Node.js, Git et une CLI Codex authentifiée. L’option `--background` lance un superviseur indépendant et enregistre ses sorties dans `.studio/launcher.log`.

```powershell
codex login status
node studio/studio.mjs start --background --night --minutes 360 --workers 2
```

Les états et correctifs sont conservés dans `.studio/` et le rapport est écrit dans `NIGHTLY_REPORT.md`. L’essai dans la session gérée a rencontré `Could not find home directory` au contrôle CLI. Zéro agent CLI a démarré pendant cet essai. Les sous-agents Codex utilisés pour l’intégration dans la session interactive sont distincts.

## Validation

- Le catalogue et la grille à douze critères se vérifient avec `node studio/architecture/check.mjs`. L’option `--gate=chapelle` exige des preuves pour un ouvrage.
- Les captures et mesures se lancent avec `node studio/visual/run.mjs --version <version> --godot <éditeur>`. La disponibilité d’un écran, de Godot et des compteurs détermine les preuves possibles.
- `NIN_VERIFY=world bash build-web.sh` vérifie la progression du prologue, les accès du terrain et la sauvegarde dans Godot.
- Le directeur lit [la mémoire compacte](TOKEN_MEMORY.md) et [la mémoire du projet](PROJECT_MEMORY.md), puis met à jour [le README](README.md) lors d’une évolution importante.

## Synchronisation GitHub

Utiliser un vrai clone du dépôt GitHub. Sur une branche `studio/review` issue de `origin/main`, intégrer les correctifs isolés après lecture du diff et exécution des vérifications. Les instantanés privés du superviseur restent locaux. Après un commit, enregistrer l’identifiant complet approuvé, puis démarrer le cycle.

```powershell
node studio/github-sync.mjs approve --repo C:/projets/Nin-Survie --branch studio/review --commit <OID>
node studio/github-sync.mjs start --repo C:/projets/Nin-Survie --branch studio/review --interval-minutes 10 --cycle-minutes 360
node studio/github-sync.mjs status --repo C:/projets/Nin-Survie --branch studio/review
```

`run-once` tente immédiatement le commit prêt. `stop` arrête proprement le cycle et `recover` vérifie son état après interruption. Les commandes prennent les mêmes arguments de clone, branche et distant. Seules les branches de revue sont admises. Un envoi normal exige un historique compatible et le cycle vérifie ensuite l’OID distant. Une panne conserve le commit approuvé et la trace de l’erreur pour un nouvel essai.

Le dossier de travail géré ne dispose pas d’un clone Git connecté et son accès HTTPS direct à GitHub échoue. La synchronisation a donc été testée avec un dépôt Git distant local. Les mises à jour effectuées par le connecteur GitHub de la session sont vérifiées séparément.
