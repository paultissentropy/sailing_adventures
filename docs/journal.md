# Journal de développement

Une entrée par session de travail : ce qui a été discuté, fait, mesuré, et ce qui reste.
Le backlog, tenu à jour, est en premier.

## Backlog

- **Punir l'empannage non contrôlé** (relevé au test du 24/11). Le passage de la bôme
  fonctionne déjà. À ajouter : casse, forte perte de vitesse ou coup de gîte quand on
  empanne GV choquée par vent soutenu. Rien d'implémenté pour l'instant.
- **Réintroduire les concepts un par un**, comme leçons de l'aventure : vent apparent,
  dérive, équilibre des voiles (loffée et abattée), foc manuel (foc à contre),
  risées. Chacun a déjà son réglage dans `BoatParams`.
- **P1** : risées visibles sur l'eau, île avec dévent et accélération dans les passes.
- **Collisions** avec les bouées et les îles.
- **Cartes** et navigation (relèvements sur la carte).
- Retirer peu à peu l'interface chiffrée au profit du ressenti (voir [vision.md](vision.md)).

## 2026-11-24 — Retours du premier test, prototype P0.1

### Retours du test

- **Recentrage** : pas un simulateur ; la jouabilité l'emporte sur le réalisme ; la
  difficulté vient de la manœuvre ; à terme, le jeu se joue au ressenti plutôt qu'aux
  chiffres (principes ajoutés à [vision.md](vision.md)).
- **Bugs** :
  - le virement n'était jamais propre, car le foc restait à contre ;
  - la jauge des écoutes était à l'envers.
- **Lisibilité** : le cap n'était pas assez visible ; on ne voyait pas d'où vient le
  vent ; la trajectoire se lisait mal, car les vaguelettes défilaient avec le vent ; il
  fallait pouvoir regarder par le travers et disposer d'un compas de relèvement.
- **Physique** : tenir le cap (seule la barre fait tourner), pas de dérive, vent réel
  seul, pas de risées pour l'instant. Garder l'arrêt bout au vent, qui plaisait.
- **Empannage** : le passage de bôme fonctionne ; il faudra le punir plus tard (backlog).

### Décisions prises ensemble

- Seule la jauge était inversée, les touches ne l'étaient pas.
- Les voiles ne voient que le vent réel.
- Il faut de la vitesse pour tourner.
- Nouvelles touches d'écoute : Q et A pour border et choquer le foc, S et Z pour la GV.
  La barre passe sur les flèches.
- **Deux appuis rapides sur « choquer » choquent en grand.** Les fausses manœuvres
  que ça provoque font partie du jeu.
- La vue de travers (J et L) sert à savoir quand virer.
- F2 masque les instruments, pour tester le jeu au ressenti.

### Réalisé

- Physique simplifiée par réglages (décision n° 11) : vent réel seul, cap tenu, pas de
  dérive, foc automatique. Deux compensations : facteur de point de près et pression
  du vent relatif.
- Commandes : nouvelles touches, double appui (`SheetInput`), vue de travers,
  masquage des instruments (F2). Les touches Espace (écoute de foc) et G (risées) sont
  retirées.
- Interface : « CAP 090° » en grand, panneau allégé (sans vent apparent), jauges
  corrigées, **compas de relèvement** en haut au centre (bouées, origine du vent,
  avant et travers du bateau), rose limitée au vent réel.
- Scène : **lignes de vent** qui filent autour du bateau, **sillage**, **ligne de cap**
  en pointillés, eau qui ne dérive presque plus.

### Mesures (10 nœuds de vent)

| Mesure | Avant (P0) | Maintenant |
|---|---|---|
| 30° du vent réel | 2,8 nœuds | 0,7 nœud (zone vent debout nette) |
| Près (50°) | 4,1 nœuds | 4,9 nœuds |
| Travers | 4,8 nœuds | 5,3 nœuds |
| Vent arrière | 3,5 nœuds | 3,5 nœuds |
| Meilleur angle de remontée | vers 40° | vers 50° (virement d'environ 100°) |
| Rotation barre à fond | environ 13°/s | 20°/s dès 1,5 m/s |

Arrêt bout au vent : entre 8 et 18 m, vérifié par un test.

### Vérifications

- 28 vérifications sur 28 réussies (`tools/test.sh`), dont les nouvelles : cap tenu,
  pas de dérive, foc jamais à contre, virement propre, double appui.
- La scène principale tourne sans erreur (`tools/smoke.sh`).
- Captures vérifiées, en vue normale et en vue de travers
  ([img/capture.png](img/capture.png), [img/capture-travers.png](img/capture-travers.png)).
  Corrigés au passage : sillage trop opaque, texte des jauges coupé.

### Limites connues

- Avec un virement d'environ 100°, une bouée « par le travers » au moment de virer est
  légèrement trop tôt : on arrive un peu sous la bouée.
- Le sillage reste une bande assez uniforme ; à affiner avec le style (P2).
- Sur le compas de relèvement, les étiquettes se chevauchent quand deux repères
  coïncident (par exemple « vent » et « Bd »).
- Pas encore testé en jeu : le ressenti du double appui et de la vue de travers reste
  à valider.

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
