import 'finance_parsing.dart';

/// Paiement (encaissement) tel que renvoyé par `GET /api/finances`
/// (`FinanceService.getPayments`, `HopeGestionV2/backend`) — la route
/// utilisée par la page Finances du web.
///
/// Noms de champs **anglais** dans la réponse (`amount`, `payment_date`,
/// `payment_method`, `reference`) : alias SQL posés par
/// `SELECT_PAYMENTS_FIELDS`, alors que la table `payments` est en français
/// (`montant`, `date_paiement`, `mode_paiement`, `reference_transaction`).
///
/// La réponse ne contient **ni le lot ni l'immeuble** (jointure limitée à
/// `leases`/`tenants`/`owners`) : seulement la référence du bail.
class Paiement {
  const Paiement({
    required this.id,
    required this.montant,
    required this.date,
    this.leaseId,
    this.scheduleId,
    this.modePaiement,
    this.reference,
    this.type,
    this.statut = 'valide',
    this.description,
    this.createdAt,
    this.referenceBail,
    this.loyerMensuel,
    this.locataireNom,
    this.locatairePrenoms,
    this.proprietaireNom,
  });

  /// `id`, `amount` et `payment_date` indispensables → `FormatException` ;
  /// le reste est optionnel (même politique que `Immeuble.fromJson`).
  factory Paiement.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final montant = asDoubleOrNull(json['amount']);
    final date = asDateOrNull(json['payment_date']);
    if (id is! int || montant == null || date == null) {
      throw const FormatException(
        'Paiement au format inattendu (id, amount ou payment_date manquant).',
      );
    }
    return Paiement(
      id: id,
      montant: montant,
      date: date,
      leaseId: asIntOrNull(json['lease_id']),
      scheduleId: asIntOrNull(json['schedule_id']),
      modePaiement: json['payment_method'] as String?,
      reference: json['reference'] as String?,
      type: json['type'] as String?,
      statut: (json['statut'] as String?) ?? 'valide',
      description: json['description'] as String?,
      createdAt: asDateTimeOrNull(json['created_at']),
      referenceBail: json['reference_bail'] as String?,
      loyerMensuel: asDoubleOrNull(json['loyer_mensuel']),
      locataireNom: json['locataire_nom'] as String?,
      locatairePrenoms: json['locataire_prenoms'] as String?,
      proprietaireNom: json['proprietaire_nom'] as String?,
    );
  }

  final int id;
  final double montant;

  /// Date du paiement (colonne `DATE`, sans heure).
  final DateTime date;
  final int? leaseId;

  /// Échéance (`payment_schedules`) soldée par ce paiement, si renseignée.
  /// Le web enregistre ses encaissements manuels **sans** `schedule_id`.
  final int? scheduleId;

  /// Texte libre côté backend (`'especes'` par défaut, `'Mobile Money'`…).
  final String? modePaiement;
  final String? reference;

  /// `'loyer'` par défaut côté backend ; texte libre (le web envoie aussi
  /// `'Caution'`, `'Charges'`…).
  final String? type;

  /// `'valide'` (défaut en base), `'en_attente'`, `'annule'`. Seuls les
  /// paiements `'valide'` comptent dans `GET /finances/stats`.
  final String statut;
  final String? description;
  final DateTime? createdAt;
  final String? referenceBail;
  final double? loyerMensuel;
  final String? locataireNom;
  final String? locatairePrenoms;
  final String? proprietaireNom;

  bool get estValide => statut == 'valide';

  /// « Prénoms Nom », ou `null` si le locataire est inconnu.
  String? get locataireNomComplet {
    final parts = [
      locatairePrenoms?.trim(),
      locataireNom?.trim(),
    ].whereType<String>().where((s) => s.isNotEmpty);
    return parts.isEmpty ? null : parts.join(' ');
  }
}
