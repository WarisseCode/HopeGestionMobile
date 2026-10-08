# Audit dépendances — Mobile (HopeGestionMobile)

**Date** : 2026-10-06
**Périmètre** : pubspec.yaml / pubspec.lock, HopeGestionMobile
**Méthode** : lecture seule, 1 sous-agent (`flutter pub outdated --show-all` + recherche web)

## 1. État des paquets

Commande : `flutter pub outdated --show-all`, aucune modification.

**Mises à jour majeures disponibles (dépendances directes)** :
- `cupertino_icons` 1.0.9 → 2.0.0 (bloqué par `^1.0.8`)
- `google_fonts` 8.2.1 → 9.0.0 (bloqué par `^8.2.1`)

**Majeures transitives** (suivent leurs parents, rien à faire) : `code_assets` 1.2.1 → 2.1.0, `record_use` 0.6.0 → 1.1.1. `cross_file` 0.3.5+5 → 0.4.0 non résoluble (bloqué par `image_picker`).

**Mineures/patchs disponibles via `flutter pub upgrade`** (16 paquets verrouillés à une version plus ancienne) : `flutter_lucide` 1.46→1.52, `image_picker` 1.2.3→1.2.4, `shared_preferences` 2.5.5→2.5.6, `url_launcher` 6.3.2→6.3.3, `image_picker_android`/`_ios`, `jni`, `objective_c`, `hooks`, `meta`, `petitparser`, `vector_math`.

**Paquets « discontinued »** : aucun.

**Déjà à la dernière version** : `dio` 5.11.1, `flutter_secure_storage` 11.2.0, `google_sign_in` 7.2.0, `signature` 6.4.0, `flutter_svg` 2.3.0 (transitif).

## 2. Contraintes de version

- Toutes les contraintes sont en `^x.y.z` : pas de `any`, pas de version figée, pas de borne haute manquante. Les correctifs mineurs/sécurité passent dans la même version majeure.
- Blocages volontaires uniquement (borne majeure) : `cupertino_icons ^1`, `google_fonts ^8`.
- Paquets `*_platform_interface` en dev_dependencies (fakes de test), cohérents avec les versions résolues ; devront suivre leurs parents lors d'une montée majeure (ex. `google_sign_in_platform_interface ^3`).
- **SDK** : `sdk: ^3.13.3` (Dart ≥3.13.3 <4), lock exige `flutter >=3.44.0`. Cohérent avec les minimums des paquets (`signature` Dart 3.7, `flutter_svg` Dart 3.9). Contrepartie : CI et postes de dev doivent être alignés sur un SDK Flutter récent (≥3.44).

## 3. Paquets à risque (natifs, date de dernière publication)

- `flutter_secure_storage` 11.2.0 — ~20 jours. Activement maintenu.
- `dio` 5.11.1 — ~32 jours. Pur Dart, maintenu.
- `flutter_svg` 2.3.0 — ~5 mois. Pur Dart, éditeur flutter.dev.
- `signature` 6.4.0 — ~2 mois. Pur Dart, pas de code natif.
- `google_sign_in` 7.2.0 — **~12 mois, à la limite du seuil d'un an**. Atténuation : implémentations natives fédérées à jour (`google_sign_in_android` 7.2.17, `_ios` 6.3.6). Non critique, à surveiller.
- Autres plugins natifs (`image_picker`, `url_launcher`, `shared_preferences`, `path_provider`) : éditeur flutter.dev, implémentations récentes, rien de plus d'un an.

## 4. Cohérence lock / manifest

Aucune divergence suspecte : chaque version verrouillée respecte sa contrainte et reste proche de la borne basse. Le lock est simplement en retard de quelques patchs (16 paquets mettables à jour sans modifier le pubspec).

## 5. Vulnérabilités connues

Accès web utilisé : GitHub Advisory Database, écosystème pub.

- `dio` : 2 avis « High » d'injection CRLF (2022, 2023), corrigés en 5.x. **5.11.1 non affectée.**
- `http` : injection d'en-têtes avant 0.13.3. **1.6.0 (transitif) non affectée.**
- `shared_preferences_android` : GHSA-3hpf-ff72-j67p (désérialisation, sévérité Low, CVSS 3.1), affecte 2.3.3, corrigée en 2.3.4. **2.4.28 non affectée.**
- `flutter_secure_storage`, `google_sign_in`, `signature`, `flutter_svg` : aucun avis publié.
- **Limite** : vérification restreinte à la base GitHub Advisories (pas d'accès API OSV).

Sources consultées : GitHub Advisory Database (https://github.com/advisories?query=ecosystem%3Apub), GHSA-3hpf-ff72-j67p (https://github.com/advisories/GHSA-3hpf-ff72-j67p), pub.dev (signature, flutter_secure_storage, google_sign_in, dio, flutter_svg — pages /versions).

## Liste priorisée

**À mettre à jour maintenant** :
- `flutter pub upgrade` (sans toucher au pubspec) : patchs `image_picker`, `url_launcher`, `shared_preferences`, `flutter_lucide`, `jni`, `objective_c`, etc. Risque de rupture faible (semver mineur/patch). Aucune vulnérabilité active à corriger.

**À surveiller** :
- `google_sign_in` : 12 mois sans release du paquet principal, à suivre pour Credential Manager Android et iOS.
- `google_fonts` 8→9 : majeure, changelog à lire. Risque modéré (relèvement possible du SDK minimum ou changement de l'API de cache/chargement). Faible impact si l'app n'utilise que `GoogleFonts.xxx()`.

**Sans urgence** :
- `cupertino_icons` 1→2 : majeure, risque faible (police d'icônes) — à vérifier seulement si l'app utilise `CupertinoIcons`, au cas où des glyphes seraient renommés.
- Majeures transitives (`code_assets`, `record_use`, `cross_file`) : suivront leurs parents automatiquement.

## Notes de synthèse

- Déjà journalisé en T-067 (`docs/JOURNAL_PROJET.md`), ce fichier est la version autonome/consultable du même rapport.
- Aucune mise à jour appliquée, audit purement diagnostique.

Lecture seule — aucun fichier de code modifié par cet audit.
