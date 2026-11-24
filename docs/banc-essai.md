# Banc d'essai

Généré par `tools/bench.sh` (ne pas modifier à la main). Un pilote automatique
exécute les manœuvres ; chaque mesure est comparée à une fourchette de référence
([references-bateaux.md](references-bateaux.md)). ✓ : dans la fourchette.
⚠ : en dehors, à examiner (ce n'est pas forcément un défaut : le jeu privilégie la
jouabilité).

Vent du nord, 10 nœuds sauf mention contraire. Mode simplifié actif.

## Quillard 6 m

| Mesure | Valeur | Référence | Verdict |
|---|---|---|---|
| Vitesse au près (50° du vent) | 4.9 nœuds | 4–5.5 nœuds | ✓ |
| Vitesse au travers | 5.2 nœuds | 4.8–6 nœuds | ✓ |
| Vitesse au vent arrière | 3.6 nœuds | 3.5–5 nœuds | ✓ |
| Meilleur angle de remontée (VMG) | 42.0 ° | 40–48 ° | ✓ |
| Rotation barre à fond, au travers | 20.0 °/s | 10–25 °/s | ✓ |
| Durée du virement (près → près, barre à 70 %) | 7.7 s | 4–8 s | ✓ |
| Perte de vitesse pendant le virement | 55.6 % | 25–55 % | ⚠ |
| Temps pour retrouver 90 % de la vitesse | 5.0 s | 3–12 s | ✓ |
| Arrêt bout au vent (erre) | 2.5 longueurs | 1.5–4 longueurs | ✓ |
| Départ arrêté au travers (90 % de la vitesse) | 8.0 s | 5–15 s | ✓ |
| Gîte au près, 10 nœuds | 11.1 ° | 8–18 ° | ✓ |
| Gîte au près, 20 nœuds (voiles bordées) | 27.1 ° | 20–35 ° | ✓ |
| Empannage GV bordée : course de la bôme | 20.6 ° | 10–50 ° | ✓ |
| Empannage GV choquée : course de la bôme | 170.0 ° | 120–175 ° | ✓ |

## Croiseur 9 m

| Mesure | Valeur | Référence | Verdict |
|---|---|---|---|
| Vitesse au près (50° du vent) | 5.9 nœuds | 5–6 nœuds | ✓ |
| Vitesse au travers | 6.3 nœuds | 5.8–7 nœuds | ✓ |
| Vitesse au vent arrière | 4.0 nœuds | 4–5.5 nœuds | ✓ |
| Meilleur angle de remontée (VMG) | 40.0 ° | 40–48 ° | ✓ |
| Rotation barre à fond, au travers | 12.9 °/s | 6–15 °/s | ✓ |
| Durée du virement (près → près, barre à 70 %) | 12.1 s | 7–15 s | ✓ |
| Perte de vitesse pendant le virement | 55.6 % | 25–55 % | ⚠ |
| Temps pour retrouver 90 % de la vitesse | 7.9 s | 5–20 s | ✓ |
| Arrêt bout au vent (erre) | 3.2 longueurs | 2.5–5 longueurs | ✓ |
| Départ arrêté au travers (90 % de la vitesse) | 13.3 s | 10–30 s | ✓ |
| Gîte au près, 10 nœuds | 11.4 ° | 10–18 ° | ✓ |
| Gîte au près, 20 nœuds (voiles bordées) | 26.8 ° | 20–30 ° | ✓ |
| Empannage GV bordée : course de la bôme | 20.6 ° | 10–50 ° | ✓ |
| Empannage GV choquée : course de la bôme | 170.0 ° | 120–175 ° | ✓ |
