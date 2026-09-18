# HopeGestion Mobile — Kit de maquettes React Native

Ce dossier contient tout ce qu'il faut pour implémenter l'application mobile
HopeGestion en React Native, à partir du prototype web validé.

## Contenu

| Fichier | Description |
| --- | --- |
| `maquettes/` | 16 captures d'écran au format 390 × 844 (iPhone 14 / Pixel) |
| `design-system.md` | Palette (OKLCH / HEX / RGB), typographie, rayons, ombres, statuts |
| `dashboard-spec.md` | Spécification détaillée du tableau de bord (priorité 1) |
| `mock-data.json` | Données de test prêtes à importer dans React Native |
| `rn-mapping.md` | Correspondance composants Web → React Native |

## Écrans capturés

1. `01-dashboard.png` — Tableau de bord (accueil)
2. `02-action-rapide.png` — Menu « Que créer ? »
3. `03-biens.png` — Liste des biens
4. `04-contacts.png` — Locataires et propriétaires
5. `05-finances.png` — Solde, entrées, sorties, opérations
6. `06-documents.png` — Quittances, contrats, factures
7. `07` → `11` — Création d'un bien (Identité, Localisation, Gestion, Médias, Succès)
8. `12` → `16` — Création d'un locataire (Identité, Documents, Finances, Confirmation, Succès)

## Ordre d'implémentation recommandé

1. Design system (thème, typographie, composants de base : carte, bouton, champ, statut)
2. Navigation par onglets (Accueil, Biens, Contacts, Finances, Docs) + bouton flottant
3. Tableau de bord — voir `dashboard-spec.md`
4. Listes : Biens, Contacts, Finances, Documents
5. Parcours de création : Bien (4 étapes), Locataire (4 étapes)

## Notes

- Polices à installer : **Libre Baskerville** (titres) et **IBM Plex Sans** (corps).
- Icônes : utiliser `lucide-react-native` (mêmes noms que dans le prototype).
- Montants en francs CFA, format « 185 000 F », abrégé « 2,45 M » / « 890 K ».
- Langue de l'interface : français.
