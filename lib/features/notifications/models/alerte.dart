import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../core/design_system.dart';

/// Catégorie mobile d'une alerte, déduite du champ `type` de
/// `GET /api/alertes` (voir [AlerteCategorie.fromType]).
///
/// Pas de catégorie « paiement reçu » : `/alertes` ne produit aucune alerte
/// de ce genre (uniquement retards, fins de bail, interventions, lots
/// vacants).
enum AlerteCategorie {
  impaye,
  contrat,
  alerte;

  /// `'Paiement'` → [impaye] (loyer en retard), `'Contrat'` → [contrat],
  /// `'Intervention'`/`'Commercial'` → [alerte]. Un type inconnu (ajouté
  /// plus tard côté backend) retombe sur [alerte], la catégorie générique,
  /// plutôt que de faire échouer toute la liste.
  static AlerteCategorie fromType(String? type) {
    switch (type) {
      case 'Paiement':
        return AlerteCategorie.impaye;
      case 'Contrat':
        return AlerteCategorie.contrat;
      default:
        return AlerteCategorie.alerte;
    }
  }

  String get label {
    switch (this) {
      case AlerteCategorie.impaye:
        return 'Impayé';
      case AlerteCategorie.contrat:
        return 'Contrat';
      case AlerteCategorie.alerte:
        return 'Alerte';
    }
  }

  Color get color {
    switch (this) {
      case AlerteCategorie.impaye:
        return AppColors.warning;
      case AlerteCategorie.contrat:
        return const Color(0xFF3B82F6);
      case AlerteCategorie.alerte:
        return const Color(0xFFF59E0B);
    }
  }

  IconData get icon {
    switch (this) {
      case AlerteCategorie.impaye:
        return LucideIcons.triangle_alert;
      case AlerteCategorie.contrat:
        return LucideIcons.file_text;
      case AlerteCategorie.alerte:
        return LucideIcons.bell_ring;
    }
  }
}

/// Une entrée de `GET /api/alertes` (`alerts[]`).
///
/// [dateCreation] est conservée brute mais n'est pas affichée : pour les
/// retards de paiement, fins de bail et lots vacants, le serveur la génère
/// à la volée (`new Date()` au moment de la requête), elle ne date donc pas
/// l'événement réel.
class Alerte {
  const Alerte({
    required this.id,
    required this.type,
    required this.categorie,
    required this.titre,
    required this.description,
    this.reference,
    this.destinataire,
    this.priorite,
    this.dateCreation,
    this.statut,
    this.link,
  });

  /// [id] obligatoire (String non vide, composite type `late_12`) : c'est
  /// lui qu'attend `POST /alertes/:id/dismiss`. Les autres champs sont
  /// tolérants (chaîne vide/`null` si absents ou mal typés).
  factory Alerte.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    if (id is! String || id.isEmpty) {
      throw const FormatException('Alerte sans "id" exploitable.');
    }
    final type = _str(json['type']);
    return Alerte(
      id: id,
      type: type,
      categorie: AlerteCategorie.fromType(type),
      titre: _str(json['titre']) ?? '',
      description: _str(json['description']) ?? '',
      reference: _str(json['reference']),
      destinataire: _str(json['destinataire']),
      priorite: _str(json['priorite']),
      dateCreation: _str(json['dateCreation']),
      statut: _str(json['statut']),
      link: _str(json['link']),
    );
  }

  final String id;

  /// `type` brut du backend (`Paiement`, `Contrat`, `Intervention`,
  /// `Commercial`).
  final String? type;
  final AlerteCategorie categorie;
  final String titre;
  final String description;
  final String? reference;
  final String? destinataire;

  /// `Urgente`, `Haute`, `Moyenne`, `Basse`.
  final String? priorite;
  final String? dateCreation;
  final String? statut;

  /// Route du front web (ex. `/dashboard/locations/12`), non exploitée par
  /// le mobile pour l'instant.
  final String? link;

  static String? _str(Object? value) => value is String ? value : null;
}
