## Journal d'évolution du projet

Après CHAQUE tâche terminée (fonctionnalité, correction, refactorisation, changement de config), mets à jour le fichier `docs/JOURNAL_PROJET.md` avant de conclure ta réponse.

### Règles
1. Ne supprime et ne réécris jamais une entrée existante, sauf pour changer son statut.
2. Ajoute les nouvelles entrées à la fin du fichier, avec un identifiant incrémental (T-001, T-002...).
3. Si une tâche modifie ou remplace une tâche antérieure :
   - change le statut de l'ancienne entrée en `Modifiée (voir T-XXX)`
   - crée une nouvelle entrée qui référence l'ancienne et explique pourquoi elle change.
4. Si le fichier n'existe pas, crée-le avec l'en-tête ci-dessous.
5. Reste factuel et concis. Ce journal servira de base au rapport final.

### Format d'une entrée
```
### T-XXX : Titre court
- **Date** : AAAA-MM-JJ
- **Statut** : Terminée | Modifiée (voir T-XXX) | Annulée
- **Type** : Fonctionnalité | Correction | Refactorisation | Config | Documentation
- **Description** : ce qui a été fait, en 2-3 phrases
- **Fichiers touchés** : liste des fichiers créés/modifiés
- **Décisions & justifications** : pourquoi ce choix technique
- **Problèmes rencontrés** : blocages et solutions (si applicable)
- **Remplace / modifie** : T-XXX (si applicable)
```

### En-tête du fichier
```
# Journal d'évolution du projet
Mis à jour automatiquement après chaque tâche.
```