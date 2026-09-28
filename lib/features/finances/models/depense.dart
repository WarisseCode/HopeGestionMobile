import 'finance_parsing.dart';

/// Dépense telle que renvoyée par `GET /api/expenses` (`expenseRoutes.ts`,
/// `HopeGestionV2/backend`) — la route utilisée par le web
/// (`FinanceExpenses.tsx`). `GET /api/depenses` (`depenseRoutes.ts`) lit la
/// même table `expenses` mais n'est appelée par aucun client.
class Depense {
  const Depense({
    required this.id,
    required this.categorie,
    required this.montant,
    required this.date,
    this.buildingId,
    this.lotId,
    this.ownerId,
    this.description,
    this.fournisseur,
    this.statut,
    this.justificatifUrl,
    this.createdAt,
    this.immeubleNom,
    this.lotReference,
  });

  factory Depense.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final categorie = json['category'];
    final montant = asDoubleOrNull(json['amount']);
    final date = asDateOrNull(json['date_expense']);
    if (id is! int || categorie is! String || montant == null || date == null) {
      throw const FormatException(
        'Dépense au format inattendu '
        '(id, category, amount ou date_expense manquant).',
      );
    }
    return Depense(
      id: id,
      categorie: categorie,
      montant: montant,
      date: date,
      buildingId: asIntOrNull(json['building_id']),
      lotId: asIntOrNull(json['lot_id']),
      ownerId: asIntOrNull(json['owner_id']),
      description: json['description'] as String?,
      fournisseur: json['supplier_name'] as String?,
      statut: json['status'] as String?,
      justificatifUrl: json['proof_url'] as String?,
      createdAt: asDateTimeOrNull(json['created_at']),
      immeubleNom: json['building_name'] as String?,
      lotReference: json['ref_lot'] as String?,
    );
  }

  final int id;

  /// Nom de catégorie (texte libre en base ; en pratique une valeur de
  /// `expense_categories.name`, voir [CategorieDepense]).
  final String categorie;
  final double montant;

  /// Date de la dépense (colonne `DATE`, sans heure).
  final DateTime date;
  final int? buildingId;
  final int? lotId;
  final int? ownerId;

  /// Chaîne vide (et non `null`) pour les dépenses créées par le web :
  /// `expenseRoutes.ts` insère `description || ''`.
  final String? description;
  final String? fournisseur;

  /// `'paid'` (écrit par `POST /expenses`) ou `'paye'` (défaut de la
  /// colonne) — deux valeurs pour le même sens, sans effet sur les calculs.
  final String? statut;

  /// Chemin serveur (`/uploads/expenses/...`) ou URL Spaces absolue — à
  /// passer par `AppConfig.resolveFileUrl` avant affichage.
  final String? justificatifUrl;
  final DateTime? createdAt;
  final String? immeubleNom;
  final String? lotReference;

  /// Intitulé affichable : la description si elle est renseignée, sinon la
  /// catégorie.
  String get intitule {
    final d = description?.trim() ?? '';
    return d.isEmpty ? categorie : d;
  }
}

/// Catégorie de dépense (`GET /api/expenses/categories`, table
/// `expense_categories`, alimentée par la migration `047_expenses_tables`).
class CategorieDepense {
  const CategorieDepense({
    required this.id,
    required this.nom,
    this.deductible = true,
    this.description,
  });

  factory CategorieDepense.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final nom = json['name'];
    if (id is! int || nom is! String) {
      throw const FormatException(
        'Catégorie de dépense au format inattendu (id ou name manquant).',
      );
    }
    return CategorieDepense(
      id: id,
      nom: nom,
      deductible: (json['is_deductible'] as bool?) ?? true,
      description: json['description'] as String?,
    );
  }

  final int id;

  /// Valeur à envoyer telle quelle dans `category` à la création.
  final String nom;
  final bool deductible;
  final String? description;
}
