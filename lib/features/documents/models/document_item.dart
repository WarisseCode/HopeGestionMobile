import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../core/design_system.dart';

/// Catégorie de document
enum DocumentCategory { quittance, contrat, facture }

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

/// Modèle d'un document numérique HopeGestion
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
      case DocumentCategory.quittance:
        return LucideIcons.receipt;
      case DocumentCategory.contrat:
        return LucideIcons.file_pen;
      case DocumentCategory.facture:
        return LucideIcons.file_text;
    }
  }

  /// Liste de démonstration conforme à la maquette 06-documents.png
  static List<DocumentItem> get mockList => [
    DocumentItem(
      id: 'doc-1',
      title: 'Quittance · Avril 2026',
      property: 'Apt. 12 — Mbour',
      category: DocumentCategory.quittance,
      status: DocumentStatus.genere,
      date: DateTime(2026, 4, 14),
    ),
    DocumentItem(
      id: 'doc-2',
      title: 'Contrat de location',
      property: 'Duplex — Almadies',
      category: DocumentCategory.contrat,
      status: DocumentStatus.signe,
      date: DateTime(2026, 4, 10),
    ),
    DocumentItem(
      id: 'doc-3',
      title: 'Facture HG-2026-041',
      property: 'Local — Plateau',
      category: DocumentCategory.facture,
      status: DocumentStatus.aRelancer,
      date: DateTime(2026, 4, 8),
    ),
    DocumentItem(
      id: 'doc-4',
      title: 'Quittance · Mars 2026',
      property: 'Villa 4 — Ngor',
      category: DocumentCategory.quittance,
      status: DocumentStatus.genere,
      date: DateTime(2026, 3, 28),
    ),
    DocumentItem(
      id: 'doc-5',
      title: 'Contrat commercial',
      property: 'Boutique B2 — Cotonou',
      category: DocumentCategory.contrat,
      status: DocumentStatus.signe,
      date: DateTime(2026, 3, 15),
    ),
    DocumentItem(
      id: 'doc-6',
      title: 'Facture HG-2026-038',
      property: 'Immeuble Le Manguier',
      category: DocumentCategory.facture,
      status: DocumentStatus.signe,
      date: DateTime(2026, 3, 5),
    ),
  ];

  static const int quittancesCount = 12;
  static const int contratsCount = 8;
  static const int facturesCount = 22;
  static const int totalDocuments = 42;
}
