/// Propriétaire géré par l'utilisateur connecté, tel que renvoyé par
/// `GET /api/owners` (`HopeGestionV2/backend/routes/ownerRoutes.ts`) —
/// utilisé pour le sélecteur "Propriétaire de rattachement" du formulaire de
/// création d'un locataire (`owner_id` requis par le backend uniquement
/// quand l'utilisateur en gère plusieurs, voir `tenantGuard.ts`).
class Owner {
  const Owner({required this.id, required this.name, this.firstName});

  factory Owner.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];
    if (id is! int || name is! String) {
      throw const FormatException(
        'Propriétaire au format inattendu (id ou name manquant).',
      );
    }
    return Owner(id: id, name: name, firstName: json['first_name'] as String?);
  }

  final int id;
  final String name;
  final String? firstName;

  String get displayName => [name, firstName]
      .where((part) => part != null && part.trim().isNotEmpty)
      .join(' ');
}
