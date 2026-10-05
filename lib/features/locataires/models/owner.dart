/// Propriétaire géré par l'utilisateur connecté, tel que renvoyé par
/// `GET /api/owners` et `GET /api/owners/:id`
/// (`HopeGestionV2/backend/routes/ownerRoutes.ts`, colonnes de la table
/// `owners`). Utilisé par l'onglet Propriétaires de l'écran Contacts, la
/// fiche `OwnerDetailScreen` et les sélecteurs "Propriétaire de
/// rattachement" (création de locataire, d'immeuble, de dépense).
class Owner {
  const Owner({
    required this.id,
    required this.name,
    this.firstName,
    this.phone,
    this.email,
    this.address,
    this.city,
    this.type,
    this.photo,
    this.totalProperties,
    this.totalLots,
  });

  /// Champs indispensables (`id`, `name`) → `FormatException` ; champs
  /// optionnels ignorés si absents/mal typés (même politique que
  /// `Immeuble.fromJson`).
  factory Owner.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];
    if (id is! int || name is! String) {
      throw const FormatException(
        'Propriétaire au format inattendu (id ou name manquant).',
      );
    }
    return Owner(
      id: id,
      name: name,
      firstName: _asStringOrNull(json['first_name']),
      phone: _asStringOrNull(json['phone']),
      email: _asStringOrNull(json['email']),
      address: _asStringOrNull(json['address']),
      city: _asStringOrNull(json['city']),
      type: _asStringOrNull(json['type']),
      photo: _asStringOrNull(json['photo']),
      // `COUNT(*)` Postgres (bigint) : renvoyé en chaîne par node-postgres.
      // Absents de `GET /owners/:id` (seule la liste les calcule).
      totalProperties: _asIntOrNull(json['total_properties']),
      totalLots: _asIntOrNull(json['total_lots']),
    );
  }

  final int id;

  /// Nom de famille (particulier) ou raison sociale (société).
  final String name;
  final String? firstName;
  final String? phone;
  final String? email;
  final String? address;
  final String? city;

  /// `'individual'` (défaut backend) ou autre valeur (société...).
  final String? type;
  final String? photo;

  /// Nombre d'immeubles rattachés (`GET /owners` uniquement). Compté côté
  /// serveur sans filtre de corbeille : indicatif seulement.
  final int? totalProperties;

  /// Nombre de lots rattachés (`GET /owners` uniquement), même réserve.
  final int? totalLots;

  String get displayName => [
    name,
    firstName,
  ].where((part) => part != null && part.trim().isNotEmpty).join(' ');

  /// Première lettre de [name] puis de [firstName] (même ordre que
  /// [displayName]) ; `?` si les deux sont vides.
  String get initials {
    final letters = [name, firstName]
        .whereType<String>()
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .map((part) => part.substring(0, 1).toUpperCase())
        .join();
    return letters.isEmpty ? '?' : letters;
  }

  /// Sous-titre de liste : téléphone et nombre de biens quand connus,
  /// repli sur « Propriétaire ».
  String get info {
    final parts = <String>[
      if (phone != null && phone!.trim().isNotEmpty) phone!.trim(),
      if (totalProperties != null)
        '$totalProperties bien${totalProperties! > 1 ? 's' : ''}',
    ];
    return parts.isEmpty ? 'Propriétaire' : parts.join(' · ');
  }
}

String? _asStringOrNull(dynamic value) => value is String ? value : null;

int? _asIntOrNull(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}
