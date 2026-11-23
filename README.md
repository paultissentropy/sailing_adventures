# Sailing Adventures

Petite aventure à la voile, semi-réaliste, en 3D mignonne. Prototype **P0** : un bac à
sable pour sentir la manœuvre d'un petit quillard (grand-voile et foc).

![Capture du prototype](docs/img/capture.png)

- Vision : [docs/vision.md](docs/vision.md)
- Modèle physique : [docs/modele-voile.md](docs/modele-voile.md)
- Décisions techniques : [docs/decisions.md](docs/decisions.md)
- Journal de développement (fait, mesuré, limites, suite) : [docs/journal.md](docs/journal.md)

## Lancer le jeu

1. Installer [Godot 4.7](https://godotengine.org/download/linux/) (version standard, pas
   .NET). Le binaire Linux est autonome : il suffit de le décompresser et de le placer dans
   le PATH, par exemple
   `sudo install -m 755 Godot_v4.7.2-stable_linux.x86_64 /usr/local/bin/godot`.
2. Lancer le jeu depuis la racine du dépôt :
   ```bash
   godot --path game
   ```
   Avec les vecteurs de forces affichés : `godot --path game -- --debug`.
   Ou ouvrir `game/project.godot` dans l'éditeur (`godot -e --path game`), puis **F5**.

Au premier lancement, Godot importe le projet (quelques secondes) et crée `game/.godot/`,
qui n'est pas versionné.

## Commandes

Les touches sont des positions physiques : elles marchent en AZERTY comme en QWERTY.
L'aide du jeu (H) affiche les noms de ton clavier.

| Action | AZERTY |
|---|---|
| Barre | Q / D ou ← / → |
| Grand-voile : border / choquer | Z / S ou ↑ / ↓ |
| Foc : border / choquer | E / A |
| Changer d'écoute de foc | Espace |
| Vent : tourner / force | 1 · 2 / 3 · 4 |
| Risées | G |
| Vecteurs de debug | F1 |
| Caméra suit le cap | C |
| Replacer le bateau | R |

## Exercices du bac à sable

Le vent vient du nord, à 10 nœuds. Le bateau part au travers, bâbord amures.

1. **Régler ses voiles** : choque jusqu'à ce que la voile faseye, puis borde juste assez
   (« bien réglée » sur les penons).
2. **Remonter au vent** jusqu'à la bouée jaune au nord. Plus tu serres le vent, plus tu
   ralentis et dérives (secteur rouge de la rose) ; vers 20–30° du vent, le bateau s'arrête.
3. **Virer de bord** avec de l'élan, puis changer d'écoute de foc (Espace). Un virement
   trop lent laisse le bateau bout au vent : le foc à contre aide à abattre.
4. **Empanner** au vent arrière : borde la grand-voile avant, sinon la bôme passe d'un coup.
5. **Barrer avec les voiles** : GV bordée seule, le bateau lofe ; foc bordé seul, il abat.
6. **Changer le vent** : 1 et 2 le font tourner, 3 et 4 changent sa force. Par 20 nœuds,
   surveille la gîte.

La caméra se tourne en cliquant-glissant et se zoome à la molette ; C la détache du cap.

## Retours utiles après une partie

Les sensations, en termes de marin : le bateau tourne-t-il trop mollement ou trop vite ?
La vitesse et la gîte sont-elles crédibles ? Les écoutes vont-elles trop vite ou trop
lentement ? Remonte-t-il trop près du vent ? Manque-t-il une information à l'écran ?
En cas d'erreur dans le terminal, la copier telle quelle.

## Outils

```bash
tools/test.sh          # tests de la simulation
tools/smoke.sh         # lance la scène sans interface et vérifie qu'il n'y a pas d'erreur
tools/polar.sh         # polaire de vitesse -> docs/img/polaire.png
tools/screenshot.sh    # capture d'écran -> docs/img/capture.png
```

Les scripts utilisent `godot` du PATH, ou la variable `GODOT=/chemin/vers/godot`.
