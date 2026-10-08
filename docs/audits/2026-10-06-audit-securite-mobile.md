# Audit sécurité — Mobile (HopeGestionMobile)

**Date** : 2026-10-06
**Périmètre** : lib/ et configuration native (Android/iOS), HopeGestionMobile
**Méthode** : lecture seule, 1 sous-agent
**Contexte exclu** (déjà traité, non re-audité) : failles IDOR backend (T-009 à T-017), `android:allowBackup="false"`, `flutter_secure_storage` pour les tokens via `TokenStorage`.

## 1. Stockage et fuite de secrets

- `shared_preferences` utilisé à 3 endroits seulement, sans enjeu : booléen d'onboarding (`lib/features/onboarding/data/onboarding_store.dart:39,47`), booléen de thème (`lib/core/theme/theme_controller.dart:33,47`), code de langue (`lib/core/i18n/locale_controller.dart:39,54`). Aucun token, mot de passe ni donnée personnelle.
- Aucun `print(`, `debugPrint(`, `log(` ni `dart:developer` dans `lib/`. Seul journal : `LogInterceptor` de dio, sous garde `kDebugMode`, en-têtes et corps désactivés (`lib/core/network/api_client.dart:87-95`). Aucune fuite en production.
- Pas de secret en dur. Seul le client ID OAuth Web Google (public, légitime) est présent, surchargeable par dart-define (`lib/core/config/app_config.dart:36-40`).
- Mot de passe d'inscription : transmis à `VerifyEmailScreen`, gardé en mémoire seulement, jamais écrit sur disque (`lib/features/auth/screens/verify_email_screen.dart:15-27`, `register_screen.dart:62`).

## 2. Réseau

- Pas de `usesCleartextTraffic` dans le manifest main (`android/app/src/main/AndroidManifest.xml:16-20`) ; autorisé seulement en debug (`android/app/src/debug/AndroidManifest.xml:12`). Pas de `network_security_config.xml` → pas de certificate pinning.
- iOS : aucune clé `NSAppTransportSecurity` → ATS strict par défaut.
- Seule URL `http://` en dur : IP d'émulateur local (`_localApiBaseUrl = 'http://10.0.2.2:5001/api'`, `app_config.dart:27`), activée uniquement sous `kDebugMode` (`:44`). Production en `https://hopegestion.com/api` (`:26`).
- `API_BASE_URL` (dart-define) et `resolveFileUrl` n'imposent aucun contrôle de schéma en release (`app_config.dart:43,62`) — l'OS bloquerait le `http://` de toute façon, mais rien ne le garantit côté app.
- `<queries>` sur le schéma `http` reste présent dans le manifest main (`AndroidManifest.xml:70-73`), impact négligeable.

## 3. Permissions et composants exposés

- Android : seule `INTERNET` déclarée, justifiée.
- iOS : `NSCameraUsageDescription` et `NSPhotoLibraryUsageDescription` justifiées par l'usage réel (`depense_screen.dart:926,932`, `avatar_picker.dart:58`, `photos_picker.dart:51`), mais les libellés ne mentionnent que les « dépenses » alors que la galerie sert aussi à l'avatar et aux photos de biens (`Info.plist:36,38`) — écart de libellé, pas une faille.
- Seul `.MainActivity` est `exported="true"`, obligatoire pour le LAUNCHER. Aucun service/receiver/provider exporté.
- Aucun deep link, aucun `CFBundleURLTypes` — rien à valider.

## 4. Fichiers locaux sensibles

- Signature de bail : PNG en mémoire (`toPngBytes`), part en base64 dans la requête, jamais écrit sur disque (`signer_bail_screen.dart:61-73`).
- Pièce d'identité : upload mocké côté UI (`_mockDocumentUploaded`, `locataire_step2_documents.dart:190`), aucun fichier traité.
- Images (justificatif, avatar, photos) : recompressées par image_picker (`imageQuality: 85`) dans le cache privé, envoyées en multipart. Copies jamais supprimées explicitement.
- PDF (quittances, justificatifs) : ouverts via `launchUrl(..., externalApplication)` (`finance_file_opener.dart:14`), donc hors sandbox de l'app. En cas d'échec, l'URL est copiée dans le presse-papiers (`:21`), lisible par d'autres apps et parfois synchronisé entre appareils.
- Aucune image n'envoie de token d'authentification (`Image.network`/`NetworkImage` partout, cache mémoire seulement, pas de cache disque).
- **Conséquence côté backend** : les fichiers `/uploads/...` (justificatifs, avatars, quittances) sont servis sans authentification — quiconque obtient l'URL y accède.

## 5. Authentification

- Biométrie : absente comme prévu (ni `local_auth` dans `pubspec.yaml`, ni occurrence dans `lib/`).
- Complexité du mot de passe entièrement déléguée au serveur. Aucun validateur mobile, seulement des textes d'aide : « 8 caractères minimum » à l'inscription (`register_screen.dart:218`) vs « 6 caractères minimum » au changement (`change_password_screen.dart:126`). Le backend applique 6 caractères au changement contre 8 + majuscule/minuscule/chiffre à l'inscription — **incohérence confirmée, politique plus faible au changement**.
- Déconnexion propre : `AuthRepository.logout()` lit le refresh token, appelle `_tokenStorage.clear()`, révocation serveur en best-effort (`auth_repository.dart:501-509`). `TokenStorage.clear()` supprime le secure storage, vide le cache mémoire, incrémente un compteur de génération anti-course (`token_storage.dart:130-135`). Session Google fermée juste après l'obtention de l'idToken (`:276`).

## 6. WebView / contenu externe

- Aucune WebView dans le projet (ni `webview_flutter` ni `InAppWebView`). Contenu externe ouvert uniquement via l'app système (`launchUrl`). Faible risque, le chemin vient toujours du backend.

## Trouvailles par priorité

**Critique** : aucune côté mobile.

**Moyen** :
1. Fichiers `/uploads` accessibles sans authentification (à corriger côté backend). Combiné à la copie presse-papiers et à l'ouverture dans une app externe, des documents sensibles (justificatifs, quittances) peuvent être consultés par des tiers. Piste : URLs signées temporaires, ou middleware d'auth sur `/uploads`.
2. Politique de mot de passe incohérente : 6 caractères au changement vs 8 + complexité à l'inscription (backend). À aligner côté serveur ; un validateur mobile serait un plus pour l'UX.

**Mineur** :
1. Pas de certificate pinning — acceptable pour l'instant, à envisager avant une diffusion plus large.
2. Schéma `http://` non contrôlé en release dans `AppConfig` — défense en profondeur, sans urgence (l'OS bloque déjà).
3. Cache image_picker jamais purgé — faible risque.
4. `<queries>` http résiduel dans le manifest main — cosmétique.
5. Libellés iOS de permission galerie/caméra incomplets (mentionnent seulement « dépenses ») — risque de rejet à la revue App Store, pas une faille de sécurité.

## Notes de synthèse

- Aucune faille critique trouvée côté mobile à ce stade.
- Les deux points moyens relèvent du backend, pas du mobile — à traiter dans un futur lot HopeGestionV2.
- Déjà journalisé en T-065 (`docs/JOURNAL_PROJET.md`), ce fichier est la version autonome/consultable du même rapport.

Lecture seule — aucun fichier de code modifié par cet audit.
