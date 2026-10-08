# Audit performance — Mobile (HopeGestionMobile)

**Date** : 2026-10-06
**Périmètre** : lib/ (Flutter, HopeGestionMobile)
**Méthode** : lecture seule, 3 sous-agents en parallèle

## 1. Listes sans pagination

Aucun repository n'envoie `page`, `limit`, `skip` ou `offset`. Chaque appel ramène la ressource complète.

- `lib/features/documents/data/baux_repository.dart:178-179` — `GET /locations` sans aucun paramètre. Appelé par `getBailActifDuLot(lotId)`, qui ramène TOUS les baux puis filtre côté client sur un seul lot (commentaire l.174 : `statut` n'est pas envoyé car le serveur n'accepte qu'une valeur). Appelant : `lib/features/biens/screens/lot_detail_screen.dart:37`, à chaque ouverture d'une fiche lot. **Volume : 500 à 5000+ baux, historique compris, croît sans fin. Pire cas du rapport.**
- `lib/features/biens/data/biens_repository.dart:76-79` — `listLots()` → `GET /biens/lots`. Volume : 200-5000.
- `lib/features/biens/data/biens_repository.dart:51-54` — `listImmeubles()` → `GET /biens/immeubles`. Volume : 50-500.
- `lib/features/locataires/data/locataires_repository.dart:42-45` — `refresh()` → `GET /locataires`. Volume : quelques centaines à 3000+.
- `lib/features/locataires/data/owners_repository.dart:51-54` — `list()` → `GET /owners`. Volume : 10-quelques centaines.
- `lib/features/documents/data/documents_repository.dart:56` — `GET /documents`. Volume : des milliers, croît chaque mois.
- `lib/features/documents/data/documents_repository.dart:79` — `GET /quittances`. Volume : ~1/bail/mois, milliers à dizaines de milliers.
- `lib/features/notifications/data/notifications_repository.dart:50-53` — `GET /alertes`. Volume : dizaines-centaines.
- `lib/features/finances/data/finances_repository.dart:81-93` et `:149-161` — `GET /finances` et `GET /expenses` : filtre période optionnel, mitigé en pratique (toujours passé par finances_screen.dart:76-77). Volume sans filtre : milliers à dizaines de milliers.
- `lib/features/finances/data/finances_repository.dart:184` — `GET /expenses/categories`. Petit référentiel, acceptable.
- `lib/features/finances/data/finances_repository.dart:234` — `GET /locations/$leaseId/echeancier`. Borné à un bail, acceptable.

## 2. Images réseau

`cached_network_image` absent de `pubspec.yaml`, aucun wrapper de cache maison, aucune occurrence de `cacheWidth`/`cacheHeight`/`ResizeImage`. **15/15 occurrences sans cache**, sur 9 écrans + 1 widget partagé (`app_avatar.dart`). Décodage en pleine résolution même pour des vignettes de 38-88px.

| Fichier:ligne | Contexte |
|---|---|
| `dashboard/widgets/dashboard_recent_rents.dart:170` | vignette bien (44x44), liste dashboard — **chaud** |
| `biens/widgets/immeuble_card.dart:150` | photo principale immeuble, liste biens_screen — **chaud** |
| `biens/screens/immeuble_detail_screen.dart:414` | carrousel photos immeuble (PageView.builder) |
| `biens/screens/immeuble_detail_screen.dart:728` | vignette lot (38x38), liste des lots — **chaud** |
| `biens/screens/lot_detail_screen.dart:143` | photo principale lot (h.180) |
| `biens/screens/lot_detail_screen.dart:161` | miniatures lot (64x64), liste horizontale |
| `biens/screens/lot_detail_screen.dart:389` | avatar occupant (44) |
| `biens/widgets/photos_picker.dart:170` | aperçu photos formulaire bien (88) |
| `finances/screens/transaction_detail_screen.dart:479` | justificatif transaction (h.220) |
| `finances/screens/transaction_detail_screen.dart:472` | justificatif plein écran (InteractiveViewer) |
| `locataires/widgets/contact_row.dart:80` | avatar liste locataires/propriétaires — **chaud** (×2 appelants) |
| `locataires/screens/owner_detail_screen.dart:272` | avatar propriétaire |
| `locataires/screens/locataire_detail_screen.dart:452` | avatar locataire |
| `locataires/widgets/avatar_picker.dart:112` | aperçu avatar formulaire |
| `core/widgets/app_avatar.dart:34` | `NetworkImage` dans `DecorationImage`, widget partagé |

## 3. Démarrage de l'app

`lib/main.dart` : **0 appel réseau bloquant avant `runApp`**. Un seul appel réseau au total (`/auth/profile` via `restoreSession()`, ligne 72), non bloquant (`unawaited`, écran de chargement affiché pendant).

4 lectures locales séquentielles indépendantes (`OnboardingStore`, `ThemeController`, `LocaleController`, `tokenStorage` — lignes 29/33/34/42) → parallélisables via `Future.wait`, gain mineur (quelques ms).

## 4. Rebuilds larges (top 5)

1. `documents/screens/documents_screen.dart:48` — `setState` à chaque frappe de recherche, sans debounce. Liste `shrinkWrap`/`NeverScrollableScrollPhysics` **non lazy** : tous les `DocumentRow` reconstruits à chaque caractère. Filtres `where` recalculés (l.129-135, l.197).
2. `locataires/screens/locataires_screen.dart:255,266` — changement d'onglet reconstruit des `Column` non lazy (boucle `for`, l.319-357) avec photos, à l'intérieur d'un `ListenableBuilder` fusionné Locataires+Owners (l.127-131).
3. `biens/screens/biens_screen.dart:65` — recherche sans debounce, mais `SliverList` lazy (l.262) donc impact moindre.
4. `finances/screens/encaisser_screen.dart:144` et `documents/screens/nouvelle_quittance_screen.dart:140` — recherche sans debounce sur tout l'écran multi-étapes ; liste `ListView.separated` lazy (l.551) mais filtrage O(n) + rebuild de l'arbre à chaque frappe.
5. `finances/screens/encaisser_screen.dart:675` — `onChanged: (_) => setState(() {})` sur le champ montant reconstruit tout le formulaire juste pour un libellé conditionnel (« acompte »). Même schéma dans `depense_screen.dart:577,607` et `edit_locataire_screen.dart:230,239,254`.

## 5. Requêtes redondantes (pas de garde de cache)

- `documents/screens/nouveau_contrat_screen.dart:157-162` `_chargerLots()` — **volontaire**, documenté (commentaire l.154-156) : statut frais requis pour éviter un 400 "déjà une affectation active" côté serveur.
- `nouveau_contrat_screen.dart:173-178` `_chargerLocataires()` — même écran, mais **sans justification métier** équivalente, recharge quand même tout à chaque ouverture.
- Schéma répété sur ~10 écrans sans garde de cache :
  - `LocatairesRepository.refresh()` (×5) : `locataires_screen.dart:45-55,68-73`, `nouvelle_quittance_screen.dart:176-181`, `encaisser_screen.dart:184-189`, `profil_screen.dart:50`, `nouveau_bien_screen.dart`/`nouveau_locataire_screen.dart` (`_ownersRepository.list()`).
  - `listLots()`/`listImmeubles()` (×6) : `immeuble_detail_screen.dart:39,42-47,76,371`, `biens_screen.dart:61,68-73`, `owner_detail_screen.dart:88-93`, `depense_screen.dart:116-125` (4 GET en parallèle à chaque ouverture), et après chaque création/modif dans `biens_repository.dart:170,242,320` (rechargement complet au lieu d'une mise à jour locale).
  - `lot_detail_screen.dart:37` — `getBailActifDuLot`, `GET /locations` complet à chaque ouverture d'un lot (cf. point 1).

## 6. Const constructors

Signal négligeable. `SizedBox`/`EdgeInsets` déjà `const` partout. Les `Icon`/`Text` restants ne peuvent pas être `const` car `AppColors.*` sont des getters dynamiques liés au thème et `AppTypography.*()` sont des fonctions. Rien à corriger.

## Priorisation

| # | Problème | Impact aujourd'hui | Effort |
|---|---|---|---|
| 1 | `GET /locations` complet pour afficher le bail d'un seul lot | Élevé maintenant, et grossit sans fin | Faible (filtre serveur `?lot_id=` ou endpoint dédié) |
| 2 | Images sans cache disque (0/15) sur écrans de liste chauds | Élevé maintenant | Moyen (`cached_network_image` + `memCacheWidth`) |
| 3 | `documents_screen` liste non lazy + rebuild à chaque frappe | Moyen maintenant, critique avec la croissance de `/documents` | Faible-moyen |
| 4 | `locataires_screen` `Column` non lazy par onglet | Moyen maintenant, critique à grande échelle | Moyen |
| 5 | Pagination absente sur `/biens/lots`, `/locataires`, `/documents`, `/quittances` | Faible aujourd'hui, bloquant à l'échelle | Élevé (API + UI) |
| 6 | Refresh sans cache sur ~10 écrans (hors cas voulu) | Faible-moyen, gaspillage systématique | Faible (`if (repo.items.isEmpty) await refresh()`) |
| 7 | Démarrage (`Future.wait` sur 4 lectures locales) | Négligeable | Trivial |
| 8 | Const constructors | Négligeable | — |

## Notes de synthèse

- Le point #1 recoupe une piste déjà notée au diagnostic de l'étape A2 (fiche lot → bail) : "optionnel : ajouter `?lot_id=` à `LeaseService.findAll`". Candidat naturel pour la phase backend plutôt qu'un correctif mobile isolé.
- Les points #3, #4 et #5 (rebuilds larges + pagination) ne deviennent vraiment gênants qu'à plusieurs centaines/milliers d'éléments par liste — à regrouper dans un futur chantier "scalabilité" plutôt qu'à corriger isolément maintenant.
- Le point #2 (cache images) est un correctif mobile pur, bas risque, gain réel dès maintenant — bon candidat pour un chantier court et autonome.

Lecture seule — aucun fichier de code modifié par cet audit.
