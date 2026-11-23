# Journal de développement

Une entrée par session de travail : ce qui a été discuté, fait, mesuré, et ce qui reste.

## 2026-11-23 — Mise en place et prototype P0

### Discussion

- **Vision** exprimée : navigation semi-réaliste où chaque manœuvre se fait comme en
  vrai ; vent changeant selon la météo et le relief ; 3D mignonne et cartoonesque ;
  rythme lent façon petite aventure ; on commence en eaux calmes pour apprendre, puis
  le vent forcit. Résumé dans [vision.md](vision.md).
- **Stack** proposée puis validée : Godot 4 + GDScript, physique de voile maison,
  simulation testable sans interface. Raisons dans [decisions.md](decisions.md).
- **Étapes** : P0 bac à sable → P1 vent variable et relief → P2 style → P3 mer et
  vent fort (tableau dans [vision.md](vision.md)).

### Réalisé (P0)

- `game/sim/` : profils (`Foil`), paramètres (`BoatParams`), champ de vent
  (`WindField`, avec risées optionnelles), simulation (`BoatSim`).
- `game/boat/` : coque procédurale, voiles procédurales, bôme, safran et barre,
  girouette en tête de mât, gréement et écoutes en traits.
- `game/world/` : eau stylisée (shader en coordonnées monde, vaguelettes qui filent
  avec le vent), bouées, deux îles décoratives.
- `game/ui/` : instruments, rose du vent avec la zone vent debout, jauges d'écoutes et
  de barre, état des voiles (penons), conseils contextuels, aide des touches.
- `game/debug/` : vecteurs de vent et de forces, trace du bateau (F1, ou `-- --debug`).
- `game/camera/` : caméra orbitale qui suit le cap (ou non, touche C).
- `tools/` : tests, lancement sans interface, polaire, captures d'écran.

### Réglages et résultats

Changements par rapport aux premières valeurs : fardage 1,2 → 2 m², traînée de base
des voiles 0,06 → 0,08, traînée induite 0,06 → 0,1, traînée d'une voile qui faseye
(+0,25), safran 0,14 → 0,2 m², amortissement en lacet réduit (le bateau tournait
trop mollement), inertie en lacet 3500 → 2800.

Mesures avec ces réglages :

| Mesure | Valeur |
|---|---|
| Près (50° du vent réel), 10 nœuds de vent | 4,1 nœuds |
| Travers, 10 nœuds | 4,8 nœuds |
| Vent arrière, 10 nœuds | 3,5 nœuds |
| Meilleur VMG au près / au portant | vers 40° / vers 150–160° du vent |
| Gîte au près, 10 / 20 nœuds | 10° / 27° |
| Arrêt bout au vent, depuis 4,9 nœuds | environ 12 m, 12 s |
| Giration barre à fond, à 4 nœuds | environ 13°/s |

Polaire complète : [img/polaire.png](img/polaire.png) (`tools/polar.sh`).

### Vérifications

- 19 vérifications sur 19 réussies (`tools/test.sh`).
- La scène principale tourne sans erreur (`tools/smoke.sh`).
- Rendu vérifié par captures. Deux corrections faites à cette occasion : l'eau
  formait des carreaux (bruit trop grossier), et le pont paraissait gris-bleu
  (couleurs de sommets lues en linéaire, lumière ambiante du ciel trop forte).

### Limites connues

- Les risées (G) existent dans la physique mais ne se voient pas encore sur l'eau.
- Aucune collision : on traverse les bouées et les îles.
- Pas de houle ; le tangage et le pilonnement sont décoratifs.
- Le foc pivote autour d'un axe vertical au point d'amure, pas autour de l'étai
  (approximation visuelle).
- Pas de vrillage des voiles, ni d'effet de la rotation du bateau sur le vent apparent.
- À 30° du vent réel, le bateau fait encore environ 2,8 nœuds avec environ 7° de
  dérive : peut-être trop généreux, à juger en jouant.
- Les paramètres du bateau sont les valeurs par défaut de `BoatParams` (pas de
  fichier `.tres` à régler dans l'éditeur).

### Prochaines étapes

1. Jouer au prototype et noter les sensations : giration, vitesse, gîte, vitesse des
   écoutes, capacité à remonter au vent, informations manquantes à l'écran.
2. Ajuster `BoatParams` selon ces retours, en vérifiant la polaire.
3. P1 : risées visibles sur l'eau (le shader lit le même champ de vent que la
   physique), île avec dévent et accélération dans les passes (carte de relief 2D).
