/// Utilisateur authentifié, tel que renvoyé par `GET /auth/profile`
/// (`HopeGestionV2/backend/routes/authRoutes.ts`).
///
/// Champs limités à ceux utiles à l'UI actuelle (nom affiché, email, rôle
/// pour le contrôle d'accès, téléphone, avatar) — `userType`/`isGuest`
/// existent côté API mais n'ont toujours pas d'usage côté mobile. `id` est
/// conservé malgré l'absence d'écran qui l'affiche : c'est l'identité
/// minimale de l'utilisateur, quasi certainement nécessaire dès la
/// prochaine phase (clé de widget, corrélation avec d'autres appels...).
///
/// [preferences] est un passthrough opaque (jamais lu ni affiché en phase
/// 4.1) : `PUT /auth/profile` (voir `AuthRepository.updateProfile`) exige ce
/// champ dans le corps de la requête et fait `JSON.stringify(preferences)`
/// côté backend sans vérifier sa présence — l'omettre enverrait la chaîne
/// littérale `"undefined"` dans une colonne JSON. Il est donc conservé tel
/// quel depuis `GET /auth/profile` pour être renvoyé inchangé à chaque mise
/// à jour, plutôt que d'écraser silencieusement des préférences définies
/// depuis le web.
class AppUser {
  const AppUser({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.role,
    this.telephone,
    this.avatarUrl,
    this.preferences = const {},
  });

  /// Extraction défensive : un cast direct (`json['id'] as int`) plante sur
  /// un champ absent ou d'un type inattendu. Les champs indispensables
  /// (`id`, `email`, `role`) sont vérifiés explicitement et lèvent une
  /// [FormatException] plutôt qu'une `TypeError` s'ils sont invalides — un
  /// appelant (`AuthRepository`) peut l'attraper spécifiquement et retomber
  /// sur un état géré au lieu de crasher. Les champs optionnels
  /// (`telephone`, `photo_url`) sont simplement ignorés s'ils ne sont pas
  /// des `String`.
  factory AppUser.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final email = json['email'];
    final role = json['role'];
    if (id is! int || email is! String || role is! String) {
      throw const FormatException(
        'Réponse de /auth/profile au format inattendu '
        '(id, email ou role manquant ou invalide).',
      );
    }

    final nom = (json['nom'] as String?)?.trim() ?? '';
    final prenom = (json['prenom'] as String?)?.trim() ?? '';
    final telephone = json['telephone'];
    final avatarUrl = json['photo_url'];
    final preferences = json['preferences'];

    return AppUser(
      id: id,
      nom: nom,
      prenom: prenom,
      email: email,
      role: role,
      telephone: telephone is String ? telephone : null,
      avatarUrl: avatarUrl is String ? avatarUrl : null,
      preferences: preferences is Map<String, dynamic> ? preferences : const {},
    );
  }

  final int id;

  /// Premier "mot" du nom complet stocké en base côté backend (découpage
  /// propre à `GET`/`PUT /auth/profile`, pas au domaine — voir
  /// [displayName]).
  final String nom;

  /// Le reste du nom complet (voir [nom]).
  final String prenom;
  final String email;
  final String role;
  final String? telephone;
  final String? avatarUrl;
  final Map<String, dynamic> preferences;

  /// Recompose `nom`+`prenom` dans l'ordre `nom prenom`, qui redonne
  /// exactement la chaîne d'origine stockée en base, pour un affichage en un
  /// seul champ.
  String get displayName =>
      [nom, prenom].where((part) => part.isNotEmpty).join(' ');

  AppUser copyWith({
    String? nom,
    String? prenom,
    String? email,
    String? telephone,
    String? avatarUrl,
  }) {
    return AppUser(
      id: id,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      email: email ?? this.email,
      role: role,
      telephone: telephone ?? this.telephone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      preferences: preferences,
    );
  }
}
