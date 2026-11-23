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
écoutes ; après un virement, le joueur change d'écoute lui-même (Espace), comme en
vrai. L'option `auto_jib` le fait automatiquement, pour plus tard, en mode débutant.

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
