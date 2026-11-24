# Références des bateaux

Valeurs de comparaison pour le banc d'essai (`tools/bench.sh`, bulletin dans
[banc-essai.md](banc-essai.md)) et pour l'analyse des parties (`tools/analyse_partie.py`).

**Ce sont des ordres de grandeur, pas des mesures.** Ils viennent de ce qu'on sait en
général de ces types de bateaux (polaires publiées de petits quillards et de croiseurs
de série, pratique courante), sans spi et par mer plate. Les fourchettes sont
volontairement larges. Une mesure hors fourchette signale un point à examiner, pas
forcément un défaut : le jeu privilégie la jouabilité.

Les fourchettes chiffrées sont dans `game/tests/bench.gd` (`REFERENCES`) et dans
`tools/analyse_partie.py` (`REFERENCES`). Il faut les garder synchronisées avec ce
document.

## Les deux bateaux du jeu

| | Quillard 6 m | Croiseur 9 m |
|---|---|---|
| Type réel comparable | petit quillard de sport ou de balade | croiseur de série de 30 pieds |
| Déplacement | environ 1,1 t | environ 4 t |
| Voilure (GV + foc) | 11 + 6,5 m² | 25 + 20 m² |
| Vitesse de carène | environ 5,6 nœuds | environ 6,8 nœuds |
| Préréglage | `game/boats/quillard_6m.tres` | `game/boats/croiseur_9m.tres` |

## Fourchettes (vent de 10 nœuds sauf mention)

| Mesure | Quillard 6 m | Croiseur 9 m | Remarque |
|---|---|---|---|
| Vitesse au près (50°) | 4–5,5 nœuds | 5–6 nœuds | |
| Vitesse au travers | 4,8–6 nœuds | 5,8–7 nœuds | proche de la vitesse de carène |
| Vitesse au vent arrière | 3,5–5 nœuds | 4–5,5 nœuds | sans spi, plus lent que le grand largue |
| Meilleur angle de remontée | 40–48° | 40–48° | angle au vent réel qui donne la meilleure progression contre le vent |
| Rotation barre à fond | 10–25 °/s | 6–15 °/s | un bateau lourd tourne plus lentement |
| Durée d'un virement (barre à 70 %) | 4–8 s | 7–15 s | d'un bord de près à l'autre |
| Perte de vitesse au virement | 25–55 % | 25–55 % | 20–30 % en régate, davantage en croisière. Fourchette incertaine |
| Reprise à 90 % de la vitesse | 3–12 s | 5–20 s | |
| Arrêt bout au vent (erre) | 1,5–4 longueurs | 2,5–5 longueurs | un bateau lourd porte plus loin |
| Départ arrêté au travers | 5–15 s | 10–30 s | jusqu'à 90 % de la vitesse |
| Gîte au près, 10 nœuds | 8–18° | 10–18° | |
| Gîte au près, 20 nœuds, voiles bordées | 20–35° | 20–30° | en vrai, on prendrait un ris |
| Empannage GV bordée : course de la bôme | 10–50° | 10–50° | empannage contrôlé |
| Empannage GV choquée : course de la bôme | 120–175° | 120–175° | la bôme traverse tout le cockpit (à punir plus tard) |

## Bout au vent

Un vrai bateau ne peut pas faire route à moins de 35 à 45° du vent réel environ.
Dans le jeu :
- les voiles ne portent plus sous `pointing_min_deg` (28° pour les deux bateaux) ;
- leur poussée revient progressivement jusqu'à `pointing_full_deg` (42° pour le quillard,
  40° pour le croiseur) ;
- sous l'angle minimal, les voiles faseyent et freinent : le bateau s'arrête sur son erre ;
- l'interface affiche « vent debout » sous 38°.
