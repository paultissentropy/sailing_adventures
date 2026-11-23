# Modèle physique de la voile

Le modèle vit dans `game/sim/`. Il ne dépend d'aucun nœud Godot : on peut le tester
sans interface (`tools/test.sh`) et en tirer la polaire du bateau (`tools/polar.sh`).

Il est **simplifié mais fondé sur les vrais principes**. On ne cherche pas la
précision d'un simulateur de course, mais des comportements justes qui émergent
du calcul plutôt que d'être scriptés.

## Conventions

- **Monde 2D** : le plan horizontal. `Vector2(x, y)` = `(X, Z)` de Godot. Le nord est
  `-Z`, l'est `+X`.
- **Cap** (`heading`) : égal à `rotation.y` de Godot. Positif = tourné vers bâbord
  (gauche). Le cap compas affiché vaut `-heading`.
- **Repère bateau** : `Vector2(avant, tribord)`. Les points sont mesurés depuis le
  centre de dérive (la quille, origine du bateau).
- **Vitesse de lacet** : positive = rotation vers bâbord.
- **Couple de lacet** d'une force `F` au point `P` : `τ = -P.avant·F.tribord + P.tribord·F.avant`.
- **Angles de voile et de safran** : positifs = bord de fuite vers tribord.
- **Gîte** : positive = gîte sur tribord.
- **Vent** : `WindField.from_deg` donne d'où vient le vent (0 = nord). Les vecteurs de
  vent sont des vitesses de l'air (vers où il va), en m/s.
- **Écoutes** : 0 = bordée à fond, 1 = choquée à fond.

## Le champ de vent

`WindField.sample(position)` donne le vent réel en tout point, par couches :

1. **Météo** : direction et force de base, qui pourront évoluer lentement.
2. **Risées** (option, touche G) : un bruit qui se déplace avec le vent et fait varier
   la force et la direction (bascules). Elles agissent déjà sur la physique, mais ne
   se voient pas encore sur l'eau.
3. **Relief** (P1) : une carte 2D précalculée pour le dévent derrière les îles,
   l'accélération dans les passes et les bascules près des côtes.

La physique et le rendu de l'eau doivent lire la même fonction : le joueur doit
pouvoir **lire le vent sur l'eau**, comme en vrai.

## Le vent apparent

```
vent apparent = vent réel − vitesse du bateau
```

C'est lui que voient les voiles et la girouette. L'angle du vent apparent (AWA) est
positif quand le vent vient de tribord (tribord amures).

## Les voiles

Chaque voile est une **plaque orientable** :

1. **Position.** Libre, une voile se mettrait « en drapeau », dans le lit du vent
   (angle `-AWA`). L'écoute limite l'angle maximal d'ouverture : la voile prend
   l'angle du drapeau, borné par l'écoute. Elle y va à vitesse finie, d'où une bôme
   qui passe brutalement lors d'un empannage non contrôlé.
2. **Incidence** `α` : l'angle entre l'écoulement et la corde de la voile.
   - `α ≈ 0` : la voile **faseye**, elle ne porte pas.
   - `α ≈ 15–25°` : portance maximale, la voile est bien réglée.
   - `α > 30°` : la voile **décroche**, la traînée augmente (trop bordée).
   - `α ≈ 90°` : voile en traînée pure, comme au vent arrière.
3. **Force** : `F = ½ ρ_air V² S (CL·n + CD·w)`, avec `w` la direction de
   l'écoulement et `n` la direction de la portance (perpendiculaire à `w`).
   `CL(α)` et `CD(α)` sont dans `Foil.coefficients` : courbe attachée jusqu'au
   décrochage, puis transition vers une plaque plane. Une voile qui faseye bat au
   vent et freine : on ajoute `sail_flutter_cd` à sa traînée quand `α < 8°`.

**Le foc** a deux écoutes : seule celle du bord choisi est en service
(`jib_side`). Si le vent le pousse vers ce bord, il est **à contre** : il pousse
l'avant du bateau sous le vent, ce qui fait abattre. Après un virement, il faut
donc changer d'écoute. Au grand largue et au vent arrière, la grand-voile
**dévente** le foc.

**Empannage.** La bôme reste de son bord tant que le vent ne passe pas
franchement de l'autre côté (marge `by_the_lee_deg`, « vent sous la bôme »), puis
elle bascule.

## Coque, quille et safran

- **Quille et safran** sont des profils symétriques (même modèle que les voiles,
  dans l'eau). La quille résiste à la dérive tant que le bateau avance ; à l'arrêt
  elle ne porte plus et le bateau glisse sur le côté.
- **Le safran** n'a d'effet que s'il y a de l'eau qui coule dessus : il faut de la
  vitesse pour barrer. En marche arrière, son effet s'inverse. Trop de barre le
  fait décrocher et freine.
- **Résistance de la coque** : quadratique, qui monte fortement à l'approche de la
  vitesse de carène (`hull_speed`, environ 5,6 nœuds).
- **Fardage** : la coque et le gréement prennent aussi le vent.

## Équilibre de route

Le couple de lacet vient de la position des forces par rapport au centre de dérive :

- la grand-voile pousse derrière : **border la GV fait lofer** ;
- le foc pousse devant : **border le foc fait abattre** ;
- la gîte déporte la poussée sous le vent et déforme la carène : **un bateau qui gîte
  devient ardent** (il veut lofer).

## Gîte

```
I · gîte'' = F_latérale_voiles · h_CE · cos(gîte) − m g GM sin(gîte) − amortissement · gîte'
```

La gîte réduit l'efficacité des voiles (facteur `cos²`) et de la quille (`cos`).

## Intégration

Le pas physique est de 1/60 s, découpé en sous-pas. Les vitesses sont intégrées
dans le repère bateau, avec les termes de couplage dus à la rotation
(`u' = Fu/mu − r·v`, `v' = Fv/mv + r·u`), et des masses ajoutées différentes en
cavalement et en embardée.

## Réglage

Les paramètres sont dans `BoatParams` (unités SI). On vérifie le réglage avec la
polaire de vitesse (`tools/polar.sh`) : pour un petit quillard de 6 m par 10 nœuds
de vent, on vise environ 4 nœuds au près, 5 à 5,5 au travers, et moins de 5 au
vent arrière. Les valeurs obtenues avec le réglage actuel sont notées dans
[journal.md](journal.md).
