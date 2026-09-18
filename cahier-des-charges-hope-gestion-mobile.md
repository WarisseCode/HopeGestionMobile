# Cahier des Charges — Application Mobile Hope Gestion

**Version** : 1.1
**Date** : Septembre 2026
**Stack technique retenu** : Flutter (Android & iOS)
**Backend** : API REST existante (Node.js/Express, PostgreSQL, JWT, multi-tenant)

---

## 1. Contexte et objectifs

Hope Gestion est une plateforme SaaS de gestion immobilière comptant 21 modules, actuellement disponible en version web. L'objectif de ce projet est de développer une **application mobile complémentaire** — et non une simple duplication du web — centrée sur les usages qui ont le plus de valeur en mobilité.

### Objectifs principaux
- Offrir un accès mobile rapide aux fonctions les plus utilisées au quotidien
- Donner aux gestionnaires une vue synthétique et des alertes en temps réel
- Faciliter le paiement et le suivi des loyers pour les locataires

### Non-objectifs (hors périmètre v1)
- Portage intégral des 21 modules web
- Fonctions d'administration avancée (paramétrage multi-tenant, configuration système)
- Reporting financier complexe (restera sur le web dans un premier temps)

---

## 2. Utilisateurs cibles (personas)

| Profil | Priorité | Besoin principal | Contexte d'usage |
|---|---|---|---|
| **Gestionnaire** | 1 | Suivre les paiements, être alerté des impayés, avoir une vue d'ensemble du patrimoine géré | Usage régulier, courtes sessions |
| **Locataire** | 2 | Consulter son contrat, payer son loyer, signaler un incident | Usage ponctuel, à la maison ou en déplacement |

> Le MVP se concentre d'abord sur le profil **Gestionnaire**, puis étend l'application au profil **Locataire** en phase suivante.

---

## 3. Fonctionnalités clés par profil (priorisées)

### 3.1 Gestionnaire (priorité 1)
- Authentification (réutilisation JWT existant)
- Dashboard synthétique : taux d'occupation, loyers encaissés/en attente
- Liste des biens avec statut (occupé, vacant, en travaux)
- Notifications d'impayés et d'échéances à venir
- Consultation des réclamations locataires

### 3.2 Locataire (priorité 2)
- Authentification (réutilisation JWT existant)
- Consultation du contrat de bail et des documents associés
- Historique et statut des paiements
- Paiement du loyer via FedaPay (mobile money)
- Notification push : rappel d'échéance, confirmation de paiement
- Signalement d'incident/réclamation avec photo

### 3.3 Fonctionnalités transverses
- Authentification biométrique (empreinte/Face ID) en complément du JWT
- Notifications push (Firebase Cloud Messaging)
- Mode sombre / thème aligné sur les couleurs déjà définies dans la maquette
- Multi-langue (français prioritaire ; anglais en option future)

---

## 4. Architecture technique

- **Frontend mobile** : Flutter, state management via Riverpod ou Bloc (à confirmer selon convention déjà utilisée sur AllôSanté/Mediva)
- **Backend** : API REST existante d'Hope Gestion ; endpoints mobiles dédiés si les payloads web sont trop lourds pour le mobile
- **Authentification** : JWT existant + refresh token ; stockage sécurisé (flutter_secure_storage)
- **Stockage local / cache** : base locale légère (SQLite via drift/sqflite, ou Hive) pour la mise en cache des données consultées (dashboard, contrats)
- **Notifications** : Firebase Cloud Messaging, déclenchées par le backend existant
- **Paiement** : intégration FedaPay mobile money (SDK ou webview selon disponibilité)
- **Multi-tenant** : le mobile doit respecter l'isolation par tenant déjà en place côté backend (contexte transmis via le token JWT)

---

## 5. Exigences non-fonctionnelles

| Catégorie | Exigence |
|---|---|
| **Performance** | Temps de chargement du dashboard < 2s en 3G |
| **Sécurité** | Chiffrement des données sensibles stockées localement ; tokens en secure storage |
| **Compatibilité** | Android 8+ et iOS 13+ |
| **Accessibilité** | Contrastes suffisants, tailles de police ajustables |
| **Design** | Respect strict de la maquette et de la charte de couleurs déjà préparées (à intégrer ultérieurement) |

---

## 6. Livrables attendus

1. Application Flutter compilée (APK/AAB pour Android, build iOS)
2. Documentation technique de l'intégration avec l'API existante
3. Guide de déploiement (stores + configuration Firebase/FedaPay)

---

## 7. Roadmap proposée

| Phase | Contenu | Durée indicative |
|---|---|---|
| **Phase 0** | Cadrage technique, intégration maquette, setup projet Flutter, connexion API/JWT | 1–2 semaines |
| **Phase 1 — MVP** | Profil Gestionnaire : auth, dashboard, liste des biens, notifications d'impayés | 3–4 semaines |
| **Phase 2** | Ajout du profil Locataire (contrat, paiement FedaPay, réclamations) | 2–3 semaines |
| **Phase 3** | Tests, corrections, publication stores | 1–2 semaines |

---

## 8. Critères d'acceptation

- Un gestionnaire peut se connecter et consulter son dashboard, la liste de ses biens et ses alertes d'impayés
- Un locataire peut se connecter, consulter son contrat et payer son loyer via FedaPay depuis l'app
- Un gestionnaire reçoit une notification push en cas d'impayé
- L'application respecte l'isolation multi-tenant du backend existant
- L'interface respecte la maquette et la charte graphique fournies

---

## 9. Points ouverts à trancher

- Riverpod ou Bloc pour la gestion d'état ?
- Endpoints API dédiés au mobile ou réutilisation stricte de l'API web existante ?
- Faut-il prévoir un mode offline pour le Gestionnaire (consultation hors-ligne du dashboard) ?
