# Audit qualité du code — Mobile (HopeGestionMobile)

**Date** : 2026-10-06
**Périmètre** : lib/ et test/ (Flutter, HopeGestionMobile)
**Méthode** : lecture seule, 3 sous-agents en parallèle

## 1. Mocks restants

Backlog connu confirmé à jour, avec un ajout non catalogué :
- `lib/features/documents/screens/apercu_non_enregistre_screen.dart:54` sert aussi la **création de contrat mockée**, pas seulement l'état des lieux (doc-comment l.7-9) — **non catalogué jusqu'ici**.
- `lib/core/widgets/app_warning_banner.dart:16` — définition de `AppWarningBanner.mockData()`.
- `lib/features/documents/screens/nouvel_etat_des_lieux_screen.dart:107` — `mockData()`.
- `lib/features/locataires/steps/locataire_step2_documents.dart:20,146-203` — `_mockDocumentUploaded`, faux nom de fichier `'CNI_recto_verso.pdf (1.8 Mo)'` (l.190).
- `lib/features/parametres/screens/parametres_screen.dart:265` — `'HopeGestion Mobile · Version 1.0.0 (MVP)'`, version codée en dur.
- `lib/features/parametres/screens/parametres_screen.dart:177-178` + `models/app_settings_repository.dart:14,31-32` — switch biométrie factice (aucun `local_auth` dans le projet).
- Aucune occurrence de Ticket ni de `firebase_messaging`/push — « Tickets inexistant » et « notifications push absentes » restent cohérents.
- Non vérifiables par ces mots-clés (aucune occurrence trouvée, ni confirmés ni infirmés) : PDF quittance B2, iOS Google Sign-In, Propriétaires étape B, switches notifications, avatar profil, mot de passe oublié.

## 2. `flutter analyze`

15 infos, 0 warning, 0 error — inchangé depuis les dernières sessions.
- `lib/features/biens/data/biens_repository.dart` : 14× `use_null_aware_elements` (lignes 150, 151, 152, 159, 160, 161, 293, 294, 295, 296, 299, 300, 301, 304).
- `lib/features/locataires/data/locataires_repository.dart` : 1× `use_null_aware_elements` (ligne 150).

## 3. TODO/FIXME/HACK/XXX

0 occurrence dans `lib/`.

## 4. Cohérence des patterns

- 8/11 repositories suivent `ChangeNotifier` + `instance`/`initialize()` statique : `auth`, `biens`, `documents`, `baux`, `finances`, `locataires`, `owners`, `notifications`.
- Exceptions :
  - `lib/features/dashboard/data/dashboard_repository.dart:15` — classe simple, **justifiée en commentaire** (l.10-14 : pas d'état partagé, données volatiles, rechargées à chaque ouverture d'écran).
  - `lib/features/biens/data/photo_upload_repository.dart:33` — classe simple, raison **non documentée**. Son `UploadPhotoResult` scellé est déclaré dans le fichier du repository, pas dans un `*_results.dart` séparé comme les autres.
  - `lib/features/parametres/models/app_settings_repository.dart:6` — `ChangeNotifier` mais sans `initialize()` (constructeur privé + `static final instance`). Dans `models/`, pas `data/`. Pas d'appel API → pas de Result. Les réglages ne sont pas persistés ; un commentaire (l.4-5) indique que la vérification par les notifications est prévue mais pas faite.
- `sealed class ...Result` utilisés systématiquement pour tout appel API. Aucun écran ne fait de try/catch sur un appel réseau.
- Try/catch direct restant (6 cas), tous sur des plugins device, jamais sur un appel API : `depense_screen.dart:174` (`pickImage`), `photos_picker.dart:50` (`pickMultiImage`), `avatar_picker.dart:56` (`pickImage`), `finance_file_opener.dart:13` (`launchUrl`), `theme_controller.dart:46`/`locale_controller.dart:53`/`token_storage.dart:64,148,157` (stockage local, `catch (_) {}` silencieux).
- Un seul `.catchError` dans la couche data : `auth_repository.dart:236`.

## 5. Code mort

- **Fichier mort** (confiance haute, tous les imports suivis depuis `lib/main.dart`, 141 fichiers parcourus) : `lib/core/theme/design_system_preview_screen.dart` — jamais importé, même pas par les tests.
- **Membres publics inutilisés** :
  - `lib/core/theme/app_radius.dart:8` `borderXs` et `:28` `borderXl` — aucune référence.
  - `lib/features/locataires/models/nouveau_locataire_form.dart:44` `typesProfile` et `:57` `modesPaiement` — déclarés, jamais référencés.
- **Publics mais usage local/test uniquement** (pas morts, pourraient être privés) : `AppConfig.filesBaseUrl`, `Echeance.estEnRetard`, `QuickActionSheet.navigateToAction`.
- **Limite de la détection** : recherche par nom, pas d'analyse sémantique — faux négatifs possibles sur extensions, `@override`, getters/setters implicites.

## 6. Duplication évidente (top 5)

1. **Verrou anti-double-envoi** — même `ValueNotifier<bool> _envoiEnCours` + garde `if (_envoiEnCours.value) return;` dans `_confirmerEnvoi(sheetContext)` : `nouveau_contrat_screen.dart:92,348-349`, `nouvelle_quittance_screen.dart:127,429-430`, `depense_screen.dart:86,308-309`, `encaisser_screen.dart:125,432-433`.
2. **Feuille récapitulatif** (`_RecapitulatifSheet`) quasi identique dans les 4 mêmes écrans — même `showModalBottomSheet(isDismissible:false, enableDrag:false, transparent)` + `ValueListenableBuilder(_envoiEnCours)` + `onModifier: pop`/`onConfirmer: _confirmerEnvoi`. Le libellé `bailLibelle` (`refLot · buildingName`) est copié mot pour mot entre `nouvelle_quittance_screen.dart:416-419` et `encaisser_screen.dart:415-418`.
3. **Feuille succès** (`_SuccesSheet` + `_apresSucces`) dupliquée dans les 4 mêmes écrans — même modal, `onTerminer` ferme la feuille et fait `pop(true)`.
4. **Widget erreur + bouton Réessayer** — quasi identique dans 6 fichiers (`documents_screen.dart:383`, `nouveau_contrat_screen.dart:757`, `nouvelle_quittance_screen.dart:725`, `depense_screen.dart:705`, `encaisser_screen.dart:785`, `finances_screen.dart:359`) + variantes inline dans ~10 autres fichiers (`lot_detail_screen.dart`, `biens_screen.dart`, `transaction_detail_screen.dart`, `immeuble_step3_proprietaire.dart`, `locataire_step1_identite.dart`, `locataires_screen.dart`, `owner_detail_screen.dart`, `locataire_detail_screen.dart`, `notifications_screen.dart`, `bail_detail_screen.dart`).
5. **Squelette de formulaire multi-étapes** (`PageController`, `_currentStep`, `_submitting`, `_goToStep`, `_submit`, retour précédent, `backLabel 'Annuler'/'Précédent'`) dupliqué entre `nouveau_bien_screen.dart` et `nouveau_locataire_screen.dart`.

## 7. Couverture de tests

**19 écrans sans aucun fichier de test** :
`login_screen`, `register_screen`, `verify_email_screen`, `offline_screen`, `unsupported_role_screen` (auth) ; `nouveau_bien_screen`, `nouveau_lot_screen`, `immeuble_cree_screen` (biens) ; `dashboard_screen` ; `signer_bail_screen`, `nouvel_etat_des_lieux_screen`, `apercu_non_enregistre_screen`, `bail_actions` (documents) ; `nouveau_locataire_screen`, `edit_locataire_screen`, `locataire_succes_screen` (locataires) ; `onboarding_screen` ; `edit_profile_screen`, `change_password_screen` (profil).

**1 repository sans test** : `app_settings_repository.dart`.

**Steps et widgets sans test** : aucun dossier test pour `biens/steps/*` ni `locataires/steps/*` ; widgets non testés : `dashboard/widgets/*`, `finances/widgets/*`, `locataires/widgets/*`, `biens/widgets/photos_picker`, `biens/widgets/immeuble_card_skeleton`, `documents/widgets/document_row` (seuls `immeuble_card` et `auth_widgets` sont testés).

## Priorités (effort/bénéfice)

1. Factoriser verrou + feuille récapitulatif + feuille succès communs (4 écrans impactés, gain immédiat).
2. Factoriser le widget erreur + Réessayer (~15 occurrences).
3. Documenter/justifier `photo_upload_repository.dart` (exception non expliquée).
4. Supprimer `design_system_preview_screen.dart` et les 4 membres morts identifiés.
5. Tests pour `app_settings_repository.dart` (seul repository non testé).
6. Tests pour écrans multi-étapes critiques (`nouveau_bien`, `nouveau_locataire`) avant de factoriser leur squelette commun.
7. Tests pour `signer_bail_screen`/`bail_actions` (actions destructives sur bail, zéro couverture).
8. Clarifier `apercu_non_enregistre_screen` dans le backlog (contrat mocké en plus de l'état des lieux).
9. Corriger les 15 infos `use_null_aware_elements` (triviales, jamais traitées).
10. Factoriser le squelette de formulaire multi-étapes (biens/locataires) une fois les tests en place.

## Notes de synthèse

- Déjà journalisé en T-066 (`docs/JOURNAL_PROJET.md`), ce fichier est la version autonome/consultable du même rapport.
- Point 7 de la priorisation (tests pour signer_bail_screen/bail_actions) mérite une attention particulière : ce sont des actions destructives sur un bail réel (résiliation, renouvellement, signature), actuellement sans aucune couverture de test.

Lecture seule — aucun fichier de code modifié par cet audit.
