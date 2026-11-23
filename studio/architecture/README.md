# Revue architecturale de Keravel

Le [catalogue](catalog.json) décrit les familles réutilisables observées dans le projet et les bâtiments qui demandent une revue. Les observations Source identifient les éléments présents dans les constructeurs Godot. Une validation exige une preuve obtenue en jeu.

## Grille de revue

| Critère | Contrôle demandé |
| --- | --- |
| Géométrie et proportions | Mesurer la hauteur des accès et vérifier les volumes depuis le niveau du personnage. |
| Silhouette | Reconnaître l’édifice depuis la rue et depuis un point éloigné. |
| Détails de façade | Examiner les encadrements, les points focaux et la lisibilité des matériaux. |
| Toiture et charpente | Vérifier pente, faîtage, rives, raccords et supports visibles. |
| Portes et fenêtres | Contrôler l’alignement, le dégagement et le fonctionnement des ouvertures prévues. |
| Matériaux et textures | Examiner les raccords, les valeurs et la cohérence des matériaux à distance utile. |
| Intérieur | Parcourir les pièces et essayer les interactions attendues. |
| Mobilier | Vérifier sa présence, son échelle, sa fonction et la place laissée au joueur. |
| Éclairage | Inspecter le jour, la nuit et les transitions aux entrées. |
| Collisions | Parcourir les angles, escaliers, seuils et portes dans les deux sens. Déplacer aussi la caméra. |
| Intégration au terrain | Suivre les chemins, vérifier les fondations et le rattachement au quartier. |
| Optimisation | Relever les mesures disponibles sur une vue de référence. Vérifier la lecture des variantes simplifiées. |

Les variantes détaillées et légères des maisons sont sélectionnées lors de la génération. Un LOD dynamique selon la distance figure au catalogue comme tâche ouverte. Les couleurs actuelles proviennent des palettes par sommet. Pour les intérieurs, vérifier les volumes effectivement visitables indépendamment de la qualité de la façade.

## Utilisation

Depuis la racine du jeu, avec Node.js disponible.

```powershell
node studio/architecture/check.mjs
node studio/architecture/check.mjs --json
node studio/architecture/check.mjs --gate=chapelle
```

Le contrôle général vérifie la structure du catalogue, l’existence des constructeurs et les références aux zones du récit. Son code de retour est `0` quand le catalogue est cohérent. Avec `--gate`, le code `1` indique une revue incomplète ou un critère en échec. Le code `2` indique une donnée ou une option invalide.

Après un contrôle en jeu, ajouter une preuve par critère sous `reviews.<id-bâtiment>.<critère>`. La preuve peut être une capture annotée, un rapport de parcours ou un relevé de mesures. Elle doit exister dans le projet et documenter le profil de rendu, la version et le point de vue utilisés.

```json
{
  "status": "pass",
  "reviewer": "Nom du testeur",
  "date": "2026-11-23",
  "note": "Description de la mesure ou du parcours observé",
  "evidence": "chemin/du/rapport.md"
}
```

Un bâtiment passe le contrôle quand tous ses critères applicables disposent d’une revue positive. Les exemptions exigent une justification et restent interdites pour les critères essentiels. Une preuve absente laisse le critère à vérifier. Une preuve en échec garde le bâtiment ouvert en correction.
