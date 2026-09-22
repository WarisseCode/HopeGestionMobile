/// Utilisateur authentifié, tel que renvoyé par `GET /auth/profile`
/// (`HopeGestionV2/backend/routes/authRoutes.ts`).
///
/// Champs limités à ceux utiles à l'UI actuelle (nom affiché, email, rôle
/// pour le contrôle d'accès, téléphone, avatar) — `permissions`,
/// `preferences`, `userType` et `isGuest` existent côté API mais n'ont pas
/// encore d'usage côté mobile. `id` est conservé malgré l'absence d'écran
/// qui l'affiche : c'est l'identité minimale de l'utilisateur, quasi
/// certainement nécessaire dès la prochaine phase (clé de widget,
/// corrélation avec d'autres appels...).
class AppUser {
  const AppUser({
    required this.id,
    required this.nom,
    required this.email,
    required this.role,
    this.telephone,
    this.avatarUrl,
  });

  /// Le backend renvoie `nom` (premier mot du nom complet stocké en base)
  /// et `prenom` (le reste) séparément — un découpage propre à cette route,
  /// pas au domaine. On les recompose ici dans l'ordre `nom prenom`, qui
  /// redonne exactement la chaîne d'origine, en un seul champ d'affichage.
  ///
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
    final displayName = [
      nom,
      prenom,
    ].where((part) => part.isNotEmpty).join(' ');

    final telephone = json['telephone'];
    final avatarUrl = json['photo_url'];

    return AppUser(
      id: id,
      nom: displayName,
      email: email,
      role: role,
      telephone: telephone is String ? telephone : null,
      avatarUrl: avatarUrl is String ? avatarUrl : null,
    );
  }

  final int id;
  final String nom;
  final String email;
  final String role;
  final String? telephone;
  final String? avatarUrl;
}
