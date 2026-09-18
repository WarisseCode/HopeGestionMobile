# HopeGestion Mobile — Design System

## Palette

| Token | Usage | OKLCH | HEX approximatif |
|-------|-------|-------|------------------|
| `--background` | Fond de l’app | `oklch(0.972 0.009 171)` | `#F0FCFA` |
| `--foreground` | Texte principal | `oklch(0.22 0.025 164)` | `#1A2E2A` |
| `--card` | Fond des cartes / bottom nav | `oklch(0.995 0.003 171)` | `#FFFFFF` |
| `--card-foreground` | Texte sur carte | `oklch(0.22 0.025 164)` | `#1A2E2A` |
| `--primary` | Boutons, accents, graphique | `oklch(0.7 0.145 174)` | `#009A9F` |
| `--primary-strong` | Hover / état actif | `oklch(0.59 0.13 179)` | `#007A7D` |
| `--primary-foreground` | Texte sur primary | `oklch(1 0 0)` | `#FFFFFF` |
| `--secondary` | Fond secondaire | `oklch(0.93 0.025 171)` | `#E6F5F3` |
| `--muted` | Fond neutre | `oklch(0.945 0.012 171)` | `#E8EFEE` |
| `--muted-foreground` | Texte secondaire | `oklch(0.5 0.02 165)` | `#6B7D7A` |
| `--border` | Bordures | `oklch(0.86 0.018 169)` | `#D4E0DE` |
| `--input` | Bordure input | `oklch(0.86 0.018 169)` | `#D4E0DE` |
| `--positive` | Statut positif / succès | `oklch(0.61 0.145 165)` | `#00A880` |
| `--positive-soft` | Fond badge positif | `oklch(0.93 0.06 165)` | `#D6F5E9` |
| `--warning` | Statut avertissement | `oklch(0.71 0.15 78)` | `#E89A2E` |
| `--warning-soft` | Fond badge avertissement | `oklch(0.95 0.06 82)` | `#FDF2D9` |
| `--phone` | Fond du cadre téléphone desktop | `oklch(0.955 0.012 171)` | `#EDF6F5` |

## Typographie

| Rôle | Police | Poids | Usage |
|------|--------|-------|-------|
| Titres / display | `Libre Baskerville` | 700 | Grands titres marketing (optionnel) |
| Titres d’écran | `IBM Plex Sans` | 600 / 700 | `Bonjour, Awa Sarr`, `Nouveau bien` |
| Corps | `IBM Plex Sans` | 400 / 500 | Textes, labels, listes |
| Chiffres / KPI | `IBM Plex Sans` | 600 / 700 | `2,45 M`, `1 560 000 F` |
| Étiquettes | `IBM Plex Sans` | 500 uppercase | `ENCAISS.`, `FLUX · 7 JOURS` |

Tailles typiques (mobile 390–430 px) :
- Titre écran : `21 px` (Accueil), `18–20 px` (formulaires)
- Sous-titre : `12–14 px`
- Corps : `12–13 px`
- Petit / légende : `9–11 px`
- Chiffres KPI : `18–30 px`

## Rayons et ombres

- Rayon par défaut : `--radius: 1rem` (16 px)
- Petit rayon : `12 px` (`rounded-xl`)
- Grand rayon : `24 px` (`rounded-2xl`)
- Très grand : `32 px` (`rounded-3xl`) pour le téléphone desktop
- Ombre douce : `0 8px 24px rgba(26,46,42,0.08)`
- Ombre action : `0 10px 20px rgba(0,154,159,0.28)`

## Icônes

- Bibliothèque web : `lucide-react`
- Équivalent React Native : `lucide-react-native`
- Taille par défaut : `17–20 px`
- Petites : `13–15 px`

Icônes clés :
- Accueil : `Home`
- Biens : `Building2`
- Contacts : `Users`
- Finances : `ArrowUpRight`
- Documents : `FileText`
- Créer / FAB : `Plus`
- Notifications : `Bell`
- Profil : `ContactRound`
- Recherche : `Search`
- Filtre : `SlidersHorizontal`
- Localisation : `MapPin`
- Téléphone : `Phone`
- Email : `Mail`
- Photo : `Camera`, `ImagePlus`
- Sauvegarde : `Save`
- Flèches : `ArrowLeft`, `ArrowRight`, `ChevronRight`
- Fermer : `X`
- Identité : `IdCard`
- Paiement : `CreditCard`, `Banknote`, `WalletCards`, `CircleDollarSign`
- Statut : `Check`, `ShieldCheck`

## Composants atomiques

### Bouton principal
- Fond : `--primary`
- Texte : `--primary-foreground`
- Hauteur : `48 px`
- Rayon : `12 px`
- Ombre : `--shadow-action`
- Hover : `--primary-strong`

### Bouton secondaire / outline
- Fond : `--card`
- Bordure : `1 px solid --border`
- Texte : `--card-foreground`
- Hover : `--secondary`

### FAB (Floating Action Button)
- Taille : `56 px`
- Fond : `--primary`
- Icône : `Plus` blanche
- Position : `bottom 94 px`, `right 24 px`
- Ombre : `--shadow-action`

### Input
- Hauteur : `48 px`
- Fond : `--background`
- Bordure : `1 px solid --input`
- Rayon : `12 px`
- Padding gauche avec icône : `40 px`
- Placeholder : `--muted-foreground`

### Carte
- Fond : `--card`
- Bordure : `1 px solid --border`
- Rayon : `16 px`
- Padding : `12 px`
- Ombre : `--shadow-soft`

### Badge / Status
- Positif : fond `--positive-soft`, texte `--positive`
- Avertissement : fond `--warning-soft`, texte `--warning`
- Neutre : fond `--muted`, texte `--muted-foreground`
- Rayon : `9999 px` (pill)
- Padding : `4 px 8 px`
- Taille texte : `8 px`, uppercase

### Avatar
- Taille : `40 px`
- Fond : `--positive-soft`
- Texte : `--primary-strong`
- Rayon : `16 px` (`rounded-2xl`) pour initiales
- Rayon : `9999 px` pour photo de profil

## Layout mobile

- Largeur max du contenu : `430 px`
- Padding horizontal : `16 px`
- Espacement vertical entre sections : `16 px`
- Bottom nav : hauteur `64 px`, positionné `bottom 16 px`, marge `16 px`
- Safe area : prévoir `padding-bottom` pour éviter que le contenu ne passe sous la bottom nav
