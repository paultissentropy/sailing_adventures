# Sailing Adventures

Jeu de navigation à voile semi-réaliste, 3D mignonne, rythme lent.

- Vision et étapes : [docs/vision.md](docs/vision.md)
- Modèle physique : [docs/modele-voile.md](docs/modele-voile.md)
- Décisions techniques et leurs raisons : [docs/decisions.md](docs/decisions.md)
- Journal (fait, mesuré, limites connues, prochaines étapes) : [docs/journal.md](docs/journal.md)

**Principe directeur** : ce n'est pas un simulateur. En cas de doute entre réalisme et
jouabilité, choisir la jouabilité (voir `docs/vision.md`). Les comportements réalistes
se désactivent par réglages dans `BoatParams` plutôt que d'être supprimés.

**À la fin de chaque session de travail**, ajouter une entrée à `docs/journal.md`
(discussion, réalisé, résultats, limites, suite) et une entrée à `docs/decisions.md`
pour tout choix difficile à défaire.

## Stack

- **Godot 4.7** (GDScript), projet dans `game/` (`game/project.godot`).
- Python 3 + matplotlib pour les outils d'analyse (`tools/`).

## Commandes

Les scripts utilisent la variable `GODOT` (par défaut `godot` dans le PATH).

```bash
tools/test.sh            # tests de la simulation, sans interface
tools/smoke.sh           # lance la scène principale sans interface pendant quelques secondes
tools/polar.sh           # polaires des deux bateaux -> tools/out/polar.csv + docs/img/polaire.png
tools/bench.sh           # banc d'essai (manœuvres types vs références) -> docs/banc-essai.md
python3 tools/analyse_partie.py [csv]   # analyse une partie enregistrée en jeu (F3)
tools/screenshot.sh [png] [secondes] [distance] [inclinaison] [rotation] [--debug]
                         # capture d'écran réelle (ouvre une fenêtre : il faut un affichage)
```

Lancer le jeu avec les vecteurs de debug affichés : `godot --path game -- --debug`.

Après avoir ajouté ou renommé un `class_name`, les scripts relancent un import
(`godot --headless --path game --import`) pour régénérer le cache des classes.

## Organisation

- `game/sim/` : physique pure (`RefCounted`/`Resource`), **aucun nœud**. Testable sans interface.
- `game/boats/` : préréglages `BoatParams` des bateaux (quillard 6 m, croiseur 9 m).
- `game/boat/` : scène du bateau, relie commandes, simulation et visuel.
- `game/world/` : eau, bouées, décor.
- `game/camera/`, `game/ui/`, `game/debug/` : caméra, interface, affichage des vecteurs.
- `game/core/` : autoloads (commandes clavier).
- `game/tests/` : tests et outils de validation lancés en `--headless -s`.
- `art/` : sources Blender (Git LFS). `tools/` : scripts shell et Python.

## Conventions

- Identifiants en anglais, commentaires et textes du jeu en français.
- GDScript typé (`var x: float`, `:=`), tabulations.
- Conventions d'axes et de signes : voir le début de `docs/modele-voile.md`. Les respecter
  partout (cap positif = vers bâbord, repère bateau `(avant, tribord)`).
- Touches définies en **touches physiques** (`physical_keycode`) dans `game/core/controls.gd`,
  pour fonctionner en AZERTY comme en QWERTY.
- Tout nouveau comportement physique doit avoir un test dans `game/tests/run_tests.gd`
  (les tests tournent sur chaque préréglage de `game/boats/`).
- Les réglages du bateau sont dans `BoatParams` et `game/boats/*.tres`. Après chaque
  changement, relancer `tools/bench.sh` et `tools/polar.sh`.
- Fourchettes de référence : `docs/references-bateaux.md`, `game/tests/bench.gd` et
  `tools/analyse_partie.py`, à garder synchronisés.
