import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../core/design_system.dart';

/// Catégorie d'un document **non enregistré** (aperçu des écrans de
/// création contrat/état des lieux, pas encore branchés au backend — la
/// quittance manuelle est réelle depuis la phase 4.6 étape B, voir
/// `NouvelleQuittanceScreen`). Les documents réels utilisent
/// `CategorieDocument` (`document.dart`).
enum DocumentCategory { contrat, etatDesLieux, facture }

/// Statut du document
enum DocumentStatus { genere, signe, aRelancer, enAttente }

extension DocumentStatusExtension on DocumentStatus {
  String get label {
    switch (this) {
      case DocumentStatus.genere:
        return 'Générée';
      case DocumentStatus.signe:
        return 'Signé';
      case DocumentStatus.aRelancer:
        return 'À relancer';
      case DocumentStatus.enAttente:
        return 'En attente';
    }
  }

  Color get backgroundColor {
    switch (this) {
      case DocumentStatus.genere:
      case DocumentStatus.signe:
        return AppColors.positiveSoft;
      case DocumentStatus.aRelancer:
      case DocumentStatus.enAttente:
        return AppColors.warningSoft;
    }
  }

  Color get textColor {
    switch (this) {
      case DocumentStatus.genere:
      case DocumentStatus.signe:
        return AppColors.primaryStrong;
      case DocumentStatus.aRelancer:
      case DocumentStatus.enAttente:
        return AppColors.warning;
    }
  }
}

/// Document saisi dans un écran de création (`NouveauContratScreen`,
/// `NouvelEtatDesLieuxScreen`) et affiché par `ApercuNonEnregistreScreen` —
/// **rien n'est envoyé au serveur**. La liste réelle utilise `Document`.
class DocumentItem {
  final String id;
  final String title;
  final String property;
  final DocumentCategory category;
  final DocumentStatus status;
  final DateTime date;
  final String size;

  const DocumentItem({
    required this.id,
    required this.title,
    required this.property,
    required this.category,
    required this.status,
    required this.date,
    this.size = '1.2 Mo',
  });

  IconData get icon {
    switch (category) {
      case DocumentCategory.contrat:
        return LucideIcons.file_pen;
      case DocumentCategory.etatDesLieux:
        return LucideIcons.clipboard_list;
      case DocumentCategory.facture:
        return LucideIcons.file_text;
    }
  }
}
