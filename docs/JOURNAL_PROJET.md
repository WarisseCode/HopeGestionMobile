# Journal d'évolution du projet
Mis à jour automatiquement après chaque tâche.

Note : les entrées T-001 à T-005 concernent le chantier « authentification mobile »,
dont le code vit dans le backend `HopeGestionV2` (repo séparé, `D:\Hope GImmo\HopeGestionV2`),
pas dans ce repo Flutter. Elles sont journalisées ici car c'est depuis cette
session/projet que le chantier est piloté.

### T-001 : Audit sécurité de l'authentification (préalable au chantier mobile)
- **Date** : 2026-09-18
- **Statut** : Terminée
- **Type** : Documentation
- **Description** : Audit en lecture seule de `backend/services/AuthService.ts` et `backend/routes/authRoutes.ts` (HopeGestionV2) pour préparer l'intégration mobile. A établi que le refresh token ne circule aujourd'hui que par cookie httpOnly, inutilisable par un client Flutter natif.
- **Fichiers touchés** : aucun (audit).
- **Décisions & justifications** : décision de créer des endpoints mobiles dédiés (`/api/auth/mobile/*`), totalement étanches du flux cookie web, plutôt que d'exposer le refresh token en JSON sur les routes web existantes (rejeté par le classificateur de sécurité — affaiblissement du modèle de menace web/XSS).
- **Problèmes rencontrés** : aucun.

### T-002 : Migration `client_type` sur `refresh_tokens`
- **Date** : 2026-09-18
- **Statut** : Terminée
- **Type** : Config
- **Description** : Ajout d'une colonne `client_type ('web'|'mobile') DEFAULT 'web'` à la table `refresh_tokens`, pour distinguer les canaux d'émission d'un refresh token.
- **Fichiers touchés** : `HopeGestionV2/backend/scripts/runMigrations.ts` (migration `064_refresh_tokens_client_type`).
- **Décisions & justifications** : `DEFAULT 'web'` garantit qu'aucune ligne ni aucun appel existant n'est affecté. Pas de migration inverse : le système de migration du projet est forward-only par conception.
- **Problèmes rencontrés** : aucun.

### T-003 : Liaison `AuthService` ↔ canal (`client_type`)
- **Date** : 2026-09-18
- **Statut** : Terminée
- **Type** : Fonctionnalité
- **Description** : `issueTokenPair`, `rotateRefreshToken` et `revokeRefreshToken` acceptent désormais un `clientType` (`'web'` par défaut). La rotation et la révocation filtrent par `client_type` en plus du hash, empêchant un token mobile d'être utilisé sur le flux web et inversement, sans message d'erreur distinct (pas d'oracle).
- **Fichiers touchés** : `HopeGestionV2/backend/services/AuthService.ts`.
- **Décisions & justifications** : la détection de réutilisation (révocation en cascade d'un token déjà révoqué) est explicitement reportée hors périmètre — un risque de déconnexion globale en cas de rafraîchissements concurrents côté web (deux onglets) a été identifié et doit être traité après audit du frontend React.
- **Problèmes rencontrés** : découverte d'un point d'émission de refresh token dupliqué dans `routes/invitationRoutes.ts`, hors `AuthService` — non modifié, couvert automatiquement par le `DEFAULT 'web'` de la migration T-002. Découverte que `changePassword`/`resetPassword` ne révoquent aujourd'hui aucun refresh token (web ou mobile) — gap préexistant, mis en backlog séparé, non corrigé ici.

### T-004 : Routes mobiles `/api/auth/mobile/{login,refresh,logout}`
- **Date** : 2026-09-18
- **Statut** : Terminée
- **Type** : Fonctionnalité
- **Description** : Ajout de trois routes dans `authRoutes.ts`, strictement additives, qui n'accèdent jamais à `req.cookies`/`res.cookie`. Le refresh token voyage exclusivement dans le corps JSON pour ces routes, avec `clientType: 'mobile'`.
- **Fichiers touchés** : `HopeGestionV2/backend/routes/authRoutes.ts`.
- **Décisions & justifications** : `/mobile/login` réutilise `loginRules` et le pattern `sendAuthError` existant ; nouvelle règle `mobileRefreshRules` (regex `^[a-f0-9]{80}$`, conforme à l'encodage réel de `crypto.randomBytes(40).toString('hex')`). Aucun limiter dédié : héritage volontaire de `authLimiter` (20/15min, déjà partagé par tout `/api/auth`).
- **Problèmes rencontrés** : aucun. 19/19 tests auth verts, `tsc --noEmit` propre.

### T-005 : Exclusion CORS + garde `Origin` sur `/api/auth/mobile/*`
- **Date** : 2026-09-18
- **Statut** : Terminée (vérification manuelle par curl bloquée, voir ci-dessous)
- **Type** : Fonctionnalité / Config
- **Description** : Les requêtes vers `/api/auth/mobile/*` ne passent plus par le middleware `cors` global et sont rejetées en 403 si elles portent un en-tête `Origin` (quelle que soit sa valeur), afin qu'un script de page web (y compris via XSS) ne puisse jamais atteindre ces routes, même en cross-origin autorisé.
- **Fichiers touchés** : `HopeGestionV2/backend/index.ts`.
- **Décisions & justifications** : détection de chemin par regex insensible à la casse (`/^\/api\/auth\/mobile(\/|$)/i`), car le routage Express ne l'est pas par défaut et rien dans le projet n'active `case sensitive routing`/`strict routing`. Options CORS existantes extraites à l'identique dans `corsMiddleware`, aucune régression sur les autres routes.
- **Problèmes rencontrés** : la vérification manuelle par curl (4 scénarios attendus) n'a pas pu être exécutée — aucune instance PostgreSQL locale n'est joignable dans cet environnement (`DB_HOST=localhost`, timeout de connexion), ce qui empêche `index.ts` de démarrer. `npm test` et `tsc --noEmit` restent verts. À refaire dès qu'une base locale est disponible.

### T-006 : Extraction de la garde CORS mobile en module dédié + tests automatisés
- **Date** : 2026-09-19
- **Statut** : Terminée
- **Type** : Refactorisation
- **Description** : La logique CORS ajoutée en T-005 (inline dans `index.ts`) a été extraite dans `middleware/mobileAuthCorsGate.ts` (`MOBILE_AUTH_PATH_RE` + `createMobileAuthCorsGate`), comportement strictement identique, pour la rendre testable indépendamment du bootstrap complet du serveur. 9 nouveaux tests ajoutés à `tests/routes/auth.test.ts` (isolation `client_type` mobile/web sur login, refresh, logout) et 6 tests dans le nouveau `tests/middleware/mobileAuthCorsGate.test.ts` (rejet 403 avec `Origin`, absence d'en-têtes CORS sur `/mobile/*`, frontière de la regex).
- **Fichiers touchés** : `HopeGestionV2/backend/middleware/mobileAuthCorsGate.ts` (nouveau), `HopeGestionV2/backend/index.ts`, `HopeGestionV2/backend/tests/routes/auth.test.ts`, `HopeGestionV2/backend/tests/middleware/mobileAuthCorsGate.test.ts` (nouveau).
- **Décisions & justifications** : extraction nécessaire car `index.ts` n'exporte pas `app`, rendant la garde CORS inline impossible à tester sans démarrer tout le serveur (DB comprise).
- **Problèmes rencontrés** : aucun. 34/34 tests (28 auth + 6 gate) verts, `tsc --noEmit` propre.

### T-007 : Tentative de validation 5.3 en environnement local — non concluante
- **Date** : 2026-09-19 → 2026-09-21
- **Statut** : Annulée (remplacée par la validation en production, voir T-008)
- **Type** : Documentation
- **Description** : Plusieurs tentatives de valider le protocole d'isolation web/mobile sur une base PostgreSQL locale ont échoué en amont des tests eux-mêmes : absence de PostgreSQL locale, puis blocage de compilation dans un fichier hors périmètre (`documentRoutes.ts`, corrigé entre-temps par l'utilisateur), puis timeouts répétés de `pool.connect()` sous `ts-node` (diagnostiqué comme un blocage de la boucle d'événements par la compilation synchrone — contourné en démarrant depuis le build compilé `dist/`), puis 4 migrations en échec sur une base amorcée uniquement via `db/init.sql` (`015`, `040`, `043`, `056` — sans rapport avec l'auth mobile ; `039` et `064`, elles, réussies).
- **Fichiers touchés** : aucun (diagnostic uniquement ; aucune modification de code, de migration ou de config).
- **Décisions & justifications** : la validation 5.3 a finalement été effectuée directement en production par l'utilisateur (voir T-008), rendant la poursuite du diagnostic local inutile pour ce chantier.
- **Problèmes rencontrés** : détaillés ci-dessus.

### T-008 : Validation 5.3 en production + clôture du chantier auth mobile
- **Date** : 2026-09-21
- **Statut** : Terminée
- **Type** : Documentation
- **Description** : Le chantier auth mobile (T-001 à T-006) est déployé en production (commit `eb7d39b`, migration `064` appliquée le 19/09). L'utilisateur a validé manuellement en production les 7 scénarios du protocole 5.3 (rejet sur `Origin` présent, login/refresh/logout mobile, isolation web↔mobile dans les deux sens, non-régression du flux web) avec un compte de test dont les tokens ont été révoqués après coup. `docs/API_DOCUMENTATION_MOBILE.md` (section authentification réécrite) et `ARCHITECTURE_RULES.md` (nouvelle règle 4) mis à jour en conséquence.
- **Fichiers touchés** : `HopeGestionV2/docs/API_DOCUMENTATION_MOBILE.md`, `HopeGestionV2/ARCHITECTURE_RULES.md`.
- **Décisions & justifications** : clôture du chantier initial. Restent en backlog séparé (hors périmètre, voir T-003) : détection de réutilisation des refresh tokens, révocation au changement/réinitialisation de mot de passe, purge des tokens expirés.
- **Problèmes rencontrés** : aucun.
- **Constat complémentaire (post-validation)** : la tentative de validation locale (T-007) a confirmé que le schéma de production **n'est plus reproductible** depuis `db/init.sql` + les migrations seules — 4 migrations (`015_fix_tenants_null_type`, `040_public_read_policies`, `043_fix_subscription_schema`, `056_soft_delete_corbeille`) échouent sur une base amorcée ainsi, faute de colonnes/tables intermédiaires que `init.sql` ne crée pas. C'est un prérequis identifié pour le futur chantier d'intégration Flutter : il faudra une base locale de référence fiable (dump de schéma à jour, ou correction d'`init.sql`) avant de pouvoir développer et tester le client mobile contre un backend local.
