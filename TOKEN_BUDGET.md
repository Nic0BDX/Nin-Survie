# Budget de tokens du studio

Le mode **ÉCO** est le défaut. Il limite la lecture aux fichiers attribués, aux différences Git pertinentes et à la mémoire compacte. Le mode **NORMAL** élargit l’analyse lorsque plusieurs systèmes interagissent. Le mode **QUALITÉ MAXIMALE** garde toute la profondeur de vérification pour une tâche P0 ou explicitement critique, par exemple une architecture de bâtiment, un système fondamental ou une scène principale.

Configurer les limites par tâche, agent, cycle et session nocturne dans `studio/token-policy.json`. Une tâche peut déclarer un plafond plus bas avec `tokenBudget`. Le directeur choisit le mode avec `qualityMode` dans la file ou avec l’option de lancement documentée dans `AUTONOMOUS_SYSTEM.md`.

| Seuil | Action |
| --- | --- |
| 70 % | Inscrire une alerte dans le suivi du cycle. |
| 85 % | Raccourcir le contexte des prochaines missions lorsque leur niveau de qualité le permet. |
| 95 % | Cesser de distribuer P2 à P4 et réserver la marge aux tâches critiques et aux validations. |
| 100 % | Fermer la distribution pour le périmètre mesuré. Garder les journaux et points de reprise. |

La CLI fournit les tokens d’entrée et de sortie dans les événements structurés de fin de tour. Les tokens d’entrée mis en cache font partie du total d’entrée. Une donnée absente est indiquée comme inconnue. Les outils de sous-agents en conversation ne fournissent pas de compteur par mission exploitable par ce script.

Les seuils contrôlent la distribution locale. La CLI peut rendre les chiffres seulement à la fin d’un tour, de sorte que ce mécanisme ne peut garantir un plafond strict pendant un appel déjà lancé. Un plafond strict nécessite une limite appliquée par le service d’exécution. Utiliser des missions courtes et un plafond de durée pour borner la taille des appels.
