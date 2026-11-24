# Décisions techniques

Chaque décision indique le choix, ses raisons, les alternatives écartées et ses
conséquences. On ajoute une entrée quand on fait un choix difficile à défaire.

## 1. Moteur : Godot 4.7, en GDScript

**Pourquoi.**
- Gratuit et open source, léger, éditeur natif sous Linux.
- Scènes (`.tscn`) et scripts en texte : ils se versionnent bien et Claude peut les
  écrire et les modifier directement.
- Adapté à une 3D stylisée et mignonne (shaders d'eau, rendu toon).
- GDScript permet d'itérer vite.

**Écartés.**
- Unity : lourd, éditeur Linux moins agréable, licence.
- Unreal : démesuré pour ce style graphique.
- Three.js / Babylon, Bevy : pas d'éditeur, il faudrait tout construire soi-même.

**Conséquence.** Si un calcul devient trop coûteux, on pourra passer les parties
critiques en C# ou en C++ (GDExtension).

## 2. Physique de voile maison, pas le moteur physique générique

**Pourquoi.** Un corps rigide avec flottabilité serait instable, difficile à régler,
et pas plus réaliste pour ce qui compte ici. Un modèle dédié, simplifié mais fondé
sur les vrais principes, fait émerger les bons comportements (zone vent debout,
safran inutile sans vitesse, foc à contre, équilibre de route…).

**Choix.** Plan horizontal (cavalement, embardée, lacet) plus la gîte. Le tangage
et le pilonnement sont décoratifs pour l'instant ; la houle viendra en P3.
Détails : [modele-voile.md](modele-voile.md).

## 3. Simulation séparée des nœuds Godot

`game/sim/` ne contient que des `RefCounted` et des `Resource`. La scène du bateau
appelle `BoatSim.step()` et lit l'état.

**Pourquoi.** On peut tester la physique sans interface (`tools/test.sh`), calculer
la polaire (`tools/polar.sh`) et régler le bateau sur des chiffres plutôt qu'au
ressenti seul.

## 4. Le bateau : quillard de 6 m, grand-voile et foc à deux écoutes

**Choix.** Un seul jeu de paramètres (`BoatParams`, unités SI). Le foc a deux
écoutes. À l'origine, le joueur changeait d'écoute lui-même après un virement
(Espace). **Depuis le 24/11/2026**, `auto_jib` est actif par défaut et le foc passe
seul sous le vent (voir n° 11).

## 5. Touches physiques déclarées dans le code

L'autoload `game/core/controls.gd` déclare les actions avec des touches *physiques*.

**Pourquoi.** Le jeu fonctionne en AZERTY comme en QWERTY, et l'aide affiche les
noms des touches du clavier du joueur.

**Conséquence.** Les actions n'apparaissent pas dans la carte des entrées (*Input Map*)
des paramètres du projet : il faut les modifier dans `controls.gd`.

## 6. Visuel procédural en attendant les modèles

Pour P0, la coque et les voiles sont générées par code, le reste est fait de formes
simples. Les voiles sont recalculées à chaque image : elles se creusent quand elles
portent et battent quand elles faseyent. Un bateau modélisé dans Blender viendra en P2.

## 7. Interpolation physique activée

La simulation tourne à 60 Hz dans `_physics_process`. L'interpolation physique de
Godot lisse l'affichage sur les écrans plus rapides. La caméra, l'eau et l'affichage
de debug sont mis à jour dans `_process` et ne sont pas interpolés.

## 8. Langue

Identifiants en anglais ; commentaires, documentation et textes du jeu en français.

## 9. Fichiers binaires lourds dans Git LFS

`.gitattributes` envoie `.blend`, l'audio, les `.glb`… dans Git LFS. **Il faut
installer git-lfs (`git lfs install`) avant d'ajouter de tels fichiers.** Les petites
images de documentation restent dans Git.

## 10. Vérification

- Tests de la simulation sans interface, un test par comportement physique.
- `tools/smoke.sh` : la scène principale tourne quelques secondes sans erreur.
- `tools/screenshot.sh` : vraie capture d'écran, pour vérifier le rendu (shaders,
  couleurs), qu'on ne peut pas voir sans affichage.

## 11. Physique simplifiée par réglages (24/11/2026)

**Contexte.** Premier test : le jeu était trop « simulateur ». Les virements n'étaient
jamais propres (le foc restait à contre), et le bateau changeait de cap tout seul.

**Choix.** Les comportements réalistes ne sont pas supprimés mais désactivés par des
réglages de `BoatParams`, pour pouvoir les réintroduire comme leçons :

| Réglage | Valeur | Effet |
|---|---|---|
| `use_apparent_wind` | faux | les voiles ne voient que le vent réel |
| `sail_yaw_effects` | faux | le cap ne change que par la barre |
| `allow_leeway` | faux | pas de dérive |
| `auto_jib` | vrai | le foc passe seul sous le vent, il n'est jamais à contre |

**Deux compensations**, invisibles pour le joueur, gardent des allures crédibles sans
vent apparent :
- un facteur de « point de près » éteint la portance sous environ 30° du vent, ce qui
  maintient une vraie zone vent debout ;
- la force des voiles utilise le vent relatif au bateau : moins de pression au portant,
  plus au près, et un arrêt bout au vent net.

**Barre.** La rotation suit directement la barre, avec une vitesse qui dépend de
l'avancement : nulle à l'arrêt, inversée en marche arrière.

## 12. Interface chiffrée réservée au développement

Le jeu final doit se jouer au ressenti. L'interface chiffrée (cap, vitesse, jauges,
rose, compas de relèvement) sert pour l'instant au développement et au réglage. F2 la
masque. Les aides visuelles sans chiffres restent affichées : lignes de vent, sillage,
ligne de cap, girouette, forme des voiles.

## 13. Deux bateaux, par préréglages (24/11/2026)

**Choix.** Deux ressources `BoatParams` : `game/boats/quillard_6m.tres` et
`game/boats/croiseur_9m.tres`. La touche B change de bateau en jeu.

- Un seul modèle 3D, dessiné pour 6 m, mis à l'échelle par `visual_scale` (1,5 pour
  le croiseur). `Boat._m()` ramène les longueurs de la simulation en unités du modèle.
- Les tests de comportement tournent sur les deux bateaux.

**Pourquoi.** Comparer un bateau vif et léger à un croiseur lourd qui garde son erre,
sans dupliquer de code. Un vrai modèle 3D par bateau viendra avec le style (P2).

## 14. Banc d'essai et fourchettes de référence (24/11/2026)

**Contexte.** On ne peut pas juger la physique « au ressenti » sans être marin.

**Choix.**
- `tools/bench.sh` : un pilote automatique exécute des manœuvres types et compare
  chaque mesure à une fourchette ([references-bateaux.md](references-bateaux.md)).
  Le bulletin est [banc-essai.md](banc-essai.md).
- L'enregistreur (F3) et `tools/analyse_partie.py` appliquent les mêmes références aux
  manœuvres du joueur.

**Limite.** Les fourchettes sont des ordres de grandeur, pas des mesures. Elles servent
à repérer les écarts grossiers.

## 15. Passage du foc lisible, « larguer pour passer » préparé (24/11/2026)

- En mode automatique, le foc se plaque tout de suite sur son nouveau bord quand le vent
  traverse l'étrave. Au portant, il suit la bôme. Le passage est signalé : battement des
  voiles dans le lit du vent, message, étiquette qui s'allume.
- La mécanique manuelle « larguer pour passer » est codée et testée derrière
  `auto_jib = false`, avec `jib_release_sheet`. Elle n'est pas encore activée en jeu :
  - les touches Q/A agissent sur l'écoute en service ;
  - écoute bordée, le foc reste à contre ;
  - larguée (double appui), il passe, et l'autre écoute est molle.

## 16. Vue cockpit (24/11/2026)

Deuxième caméra (touche V) : derrière le barreur, un peu au-dessus de sa tête, sans être
une vraie première personne. Elle suit le cap et la moitié de la gîte, mais pas le
tangage, pour éviter le mal de mer. Elle prépare un jeu plus « au ressenti ».

