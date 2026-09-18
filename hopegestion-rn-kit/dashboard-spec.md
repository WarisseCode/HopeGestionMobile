# HopeGestion Mobile — Spécification du tableau de bord

## Vue d’ensemble

Le tableau de bord est l’écran d’accueil de l’application. Il présente un résumé de l’activité immobilière du gestionnaire et donne accès aux actions de création rapide.

## Structure de l’écran

```text
┌─────────────────────────────────┐
│  LUNDI 14 AVRIL          🔔 👤 │  Header
│  Bonjour, Awa Sarr              │
├─────────────────────────────────┤
│ [ENCAISS.] [DÉPENSES] [IMPAYÉS] │  KPIs (3 cartes)
│  2,45 M     890 K      320 K    │
├─────────────────────────────────┤
│  FLUX · 7 JOURS                 │  Graphique
│  Net +1 560 000 F               │
│  ████ ░░░░ ...                  │
├─────────────────────────────────┤
│  CRÉER                    4     │  Section actions
│ [🏢 Bien] [👤 Locataire] ...   │
├─────────────────────────────────┤
│  LOYERS RÉCENTS        Tout voir│  Liste
│  Apt. 12 — Mbour   185 000 Payé │
│  Duplex — Almadies 450 000 Att. │
│  Local — Plateau   320 000 Imp. │
├─────────────────────────────────┤
│        [   +   ]                │  FAB
├─────────────────────────────────┤
│ Accueil Biens Contacts Fin Docs │  Bottom nav
└─────────────────────────────────┘
```

## Header

- **Date** : jour de la semaine + date (ex. `LUNDI 14 AVRIL`).
- **Titre** : `Bonjour, Awa Sarr`.
- **Actions** :
  - Bouton profil (icône `ContactRound`) à droite.
  - Bouton notifications (icône `Bell`) avec un point indicateur vert en haut à droite.

## KPIs (3 cartes en grille)

| Label | Valeur | Note | Couleur note |
|-------|--------|------|--------------|
| ENCAISS. | `2,45 M` | `+12% ce mois` | `--primary` (positif) |
| DÉPENSES | `890 K` | `24% du CA` | `--muted-foreground` (neutre) |
| IMPAYÉS | `320 K` | `3 factures` | `--muted-foreground` (neutre) |

- Chaque carte a un fond `--card`, une bordure `--border`, un rayon `16 px`.
- Label en petit uppercase `--muted-foreground`.
- Valeur en `18 px` semibold `--foreground`.
- Note en `9 px`.

## Graphique « Flux · 7 jours »

- Titre : `FLUX · 7 JOURS` (uppercase, `--muted-foreground`).
- Sous-titre : `Net <valeur>` en `--primary`.
- Légende : `● Entrées` (couleur `--primary`) et `● Sorties` (couleur `--muted-foreground` à 25 %).
- Barres : 7 groupes de deux barres verticales.
  - Barre d’entrées : couleur `--primary`, largeur `12 px`.
  - Barre de sorties : couleur `--muted-foreground` à 25 %, hauteur = `max(24 %, entrées - 25 %)`.
- Axe X : jours `12` à `18`.
- Hauteur du graphique : `96 px`.

Données du graphique :
```json
[
  { "day": 12, "in": 58, "out": 35 },
  { "day": 13, "in": 45, "out": 20 },
  { "day": 14, "in": 72, "out": 40 },
  { "day": 15, "in": 54, "out": 30 },
  { "day": 16, "in": 78, "out": 45 },
  { "day": 17, "in": 61, "out": 32 },
  { "day": 18, "in": 48, "out": 25 }
]
```

## Section CRÉER

- Titre `CRÉER` à gauche, badge `4 actions` à droite.
- Grille de 4 boutons secondaires (`Bien`, `Locataire`, `Facture`, `Quittance`).
- Chaque bouton : icône au-dessus, label en dessous, hauteur `72 px`.
- Icône en `--primary`, fond du bouton `--card`, bordure `--border`.

## Loyers récents

- Titre `LOYERS RÉCENTS` + lien `Tout voir` à droite (`--primary`).
- Liste de 3 éléments avec séparateur.
- Chaque élément :
  - Image miniature du bien (`40 px`, `rounded-xl`, `object-cover`).
  - Nom du bien + locataire.
  - Montant + statut.
  - Flèche `ChevronRight`.

| Bien | Locataire | Montant | Statut |
|------|-----------|---------|--------|
| Apt. 12 — Mbour | Yacine Diop | 185 000 F | Payé |
| Duplex — Almadies | Fatou Ndiaye | 450 000 F | En attente |
| Local — Plateau | M. Camara | 320 000 F | Impayé |

## FAB (Floating Action Button)

- Icône `Plus`.
- Position : `bottom 94 px`, `right 24 px`.
- Ouvre le menu `ACTION RAPIDE / Que créer ?`.

## Bottom navigation

- 5 onglets : `Accueil`, `Biens`, `Contacts`, `Finances`, `Docs`.
- Hauteur : `64 px`.
- Fond `--card`, bordure `--border`, ombre `--shadow-soft`.
- Onglet actif : fond `--positive-soft`, texte `--primary-strong`.
- Onglet inactif : texte `--muted-foreground`.

## Interactions

| Action | Résultat |
|--------|----------|
| Tap sur FAB `+` | Ouvre le menu action rapide |
| Tap sur une action `CRÉER` | Même comportement que le FAB |
| Tap sur un loyer récent | Navigation vers le détail (prévue) |
| Tap sur un onglet | Change d’écran |
| Pull-to-refresh | Recharge les données du dashboard |

## États

- **Chargement** : squelette des KPIs et du graphique.
- **Vide** : si aucun loyer récent, afficher `Empty` avec texte `Aucun loyer récent`.
- **Erreur** : bannière discrète avec bouton `Réessayer`.
