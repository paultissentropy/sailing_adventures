# Vision — Sailing Adventures

Une petite aventure à la voile, en 3D, au rythme lent.

## Intention

- **Navigation semi-réaliste.** Le joueur manœuvre son bateau comme en vrai : barre,
  écoute de grand-voile, écoutes de foc. Chaque manœuvre (virement, empannage,
  changement d'allure, départ arrêté) se fait selon les principes réels de la voile.
- **Vent vivant.** Le vent change avec la météo et le relief : dévent derrière les
  îles, accélération dans les passes, risées qui se lisent sur l'eau.
- **Esthétique mignonne.** 3D cartoonesque, couleurs douces, bateau un peu jouet.
- **Rythme lent.** Une petite aventure contemplative, sans pression de score.

## Le bateau

Un petit quillard monocoque d'environ 6 m : un mât, une grand-voile sur bôme et une
voile d'avant (foc) avec deux écoutes.

## Progression

1. **Eaux calmes.** On apprend pas à pas : les allures, régler les voiles, virer de
   bord, empanner, repartir après être resté bout au vent.
2. **Le vent forcit.** Rafales, gîte, besoin de choquer et d'anticiper.
3. **Zones de gros temps.** Vent fort et mer formée, où chaque manœuvre compte.

## Principes de conception

- Le réalisme du comportement prime sur le réalisme graphique.
- Tout ce qui compte doit se lire : girouette, penons, risées sur l'eau, gîte.
- Les comportements réalistes doivent **émerger du modèle physique** plutôt
  qu'être scriptés (voir [modele-voile.md](modele-voile.md)).

## Étapes du prototype

| Étape | Contenu | Critère de réussite |
|---|---|---|
| **P0 — bac à sable** | Eau plate, bouées, bateau en formes simples, vent réglable, interface et affichage de debug | On fait toutes les allures, on vire, on empanne, et on reste bloqué vent debout après un virement raté |
| **P1 — vent variable** | Risées visibles sur l'eau, île avec dévent | On lit le vent sur l'eau et on en profite |
| **P2 — style** | Shader toon, eau stylisée, bateau modélisé, caméra douce | Ça a l'air mignon |
| **P3 — mer et vent fort** | Houle (vagues de Gerstner), vent fort | Le gros temps est impressionnant mais jouable |
