import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../models/locataire.dart';
import 'locataire_results.dart';

/// Source de vérité unique pour la liste des locataires réels, partagée par
/// tous les écrans — même rôle que `BiensRepository`/`ContactsRepository`
/// (mockés), mais avec un constructeur public prenant l'[ApiClient] en
/// paramètre (même raison qu'`AuthRepository` : les tests construisent leur
/// propre instance, ne touchent jamais à [instance]/[initialize]).
class LocatairesRepository extends ChangeNotifier {
  LocatairesRepository({required ApiClient apiClient})
    // ignore: prefer_initializing_formals
    : _apiClient = apiClient;

  static LocatairesRepository? _instance;

  static LocatairesRepository get instance {
    final current = _instance;
    if (current == null) {
      throw StateError(
        'LocatairesRepository.instance accédée avant LocatairesRepository.initialize().',
      );
    }
    return current;
  }

  static void initialize(LocatairesRepository repository) {
    _instance = repository;
  }

  final ApiClient _apiClient;

  List<Locataire> _items = [];

  List<Locataire> get items => List.unmodifiable(_items);

  /// `GET /api/locataires` — pas de pagination côté backend (vérifié dans
  /// `locataireRoutes.ts`), la liste complète est renvoyée en un appel.
  Future<LocatairesListResult> refresh() async {
    try {
      final response = await _apiClient.request<Map<String, dynamic>>(
        '/locataires',
      );
      final raw = response.data?['locataires'];
      if (raw is! List) {
        throw const FormatException(
          'Réponse de /locataires sans champ "locataires" exploitable.',
        );
      }
      _items = raw
          .whereType<Map<String, dynamic>>()
          .map(Locataire.fromJson)
          .toList();
      notifyListeners();
      return LocatairesListSuccess(_items);
    } on ApiException catch (e) {
      return LocatairesListFailure(e.message, e.type);
    } on FormatException catch (e) {
      return LocatairesListFailure(e.message, ApiExceptionType.unknown);
    }
  }

  /// `GET /api/locataires/:id` — ne touche pas à [items] : l'écran de détail
  /// gère son propre état de chargement, indépendant de la liste.
  Future<LocataireDetailResult> getDetail(int id) async {
    try {
      final response = await _apiClient.request<Map<String, dynamic>>(
        '/locataires/$id',
      );
      final data = response.data;
      final rawLocataire = data?['locataire'];
      if (rawLocataire is! Map<String, dynamic>) {
        throw const FormatException(
          'Réponse de /locataires/:id sans champ "locataire" exploitable.',
        );
      }
      final locataire = Locataire.fromJson(rawLocataire);
      final baux = (data?['baux'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(TenantLease.fromJson)
          .toList();
      final paiements = (data?['paiements'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(TenantPayment.fromJson)
          .toList();
      return LocataireDetailSuccess(locataire, baux, paiements);
    } on ApiException catch (e) {
      return LocataireDetailFailure(e.message, e.type);
    } on FormatException catch (e) {
      return LocataireDetailFailure(e.message, ApiExceptionType.unknown);
    }
  }

  /// `POST /api/locataires`. Ne renvoie que `{message, id, invitation_code}`
  /// (jamais le locataire complet créé, vérifié dans `locataireRoutes.ts`) :
  /// après succès, [refresh] est relancée pour que [items] reflète la ligne
  /// réelle (avec ses agrégats calculés côté serveur), plutôt que de
  /// reconstruire un `Locataire` local en devinant ces champs. Un échec de
  /// ce [refresh] ne fait pas échouer [create] (déjà réussie côté serveur).
  ///
  /// [ownerId] n'est à fournir explicitement que lorsque l'utilisateur gère
  /// plusieurs propriétaires (sinon résolu automatiquement côté serveur —
  /// voir `tenantGuard.ts`) ; omis (`null`), il n'est pas envoyé.
  Future<CreateLocataireResult> create({
    required String nom,
    required String prenoms,
    required String telephonePrincipal,
    String? email,
    String? telephoneSecondaire,
    String? nationalite,
    String? typePiece,
    String? numeroPiece,
    String? dateExpirationPiece,
    String type = 'Locataire',
    String? modePaiementPreferentiel,
    String? adresseActuelle,
    bool paiementEchelonne = false,
    int? ownerId,
    String? photoProfilUrl,
  }) async {
    try {
      final response = await _apiClient.request<Map<String, dynamic>>(
        '/locataires',
        method: 'POST',
        data: {
          'nom': nom,
          'prenoms': prenoms,
          'telephone_principal': telephonePrincipal,
          if (email != null && email.isNotEmpty) 'email': email,
          if (telephoneSecondaire != null && telephoneSecondaire.isNotEmpty)
            'telephone_secondaire': telephoneSecondaire,
          if (nationalite != null && nationalite.isNotEmpty)
            'nationalite': nationalite,
          if (typePiece != null && typePiece.isNotEmpty)
            'type_piece': typePiece,
          if (numeroPiece != null && numeroPiece.isNotEmpty)
            'numero_piece': numeroPiece,
          if (dateExpirationPiece != null && dateExpirationPiece.isNotEmpty)
            'date_expiration_piece': dateExpirationPiece,
          'type': type,
          if (modePaiementPreferentiel != null &&
              modePaiementPreferentiel.isNotEmpty)
            'mode_paiement_preferentiel': modePaiementPreferentiel,
          if (adresseActuelle != null && adresseActuelle.isNotEmpty)
            'adresse_actuelle': adresseActuelle,
          'paiement_echelonne': paiementEchelonne,
          if (ownerId != null) 'owner_id': ownerId,
          if (photoProfilUrl != null && photoProfilUrl.isNotEmpty)
            'photo_profil_url': photoProfilUrl,
        },
      );
      final id = response.data?['id'];
      if (id is! int) {
        throw const FormatException(
          'Réponse de POST /locataires sans champ "id" exploitable.',
        );
      }
      await refresh();
      return CreateLocataireSuccess(id);
    } on ApiException catch (e) {
      if (e.statusCode == 409) {
        return CreateLocataireDuplicate(e.message);
      }
      if (e.type == ApiExceptionType.validation) {
        return CreateLocataireValidationFailed(e.message, e.fieldErrors);
      }
      return CreateLocataireFailure(e.message, e.type);
    } on FormatException catch (e) {
      return CreateLocataireFailure(e.message, ApiExceptionType.unknown);
    }
  }

  /// `PUT /api/locataires/:id`. **Tous les champs sont réécrits sans
  /// `COALESCE` côté backend** (vérifié dans `locataireRoutes.ts`) : omettre
  /// un champ optionnel l'efface (`NULL`) plutôt que de le laisser inchangé.
  /// D'où la signature à champs obligatoires ci-dessous (même valeur
  /// qu'avant si l'utilisateur ne l'a pas modifiée) plutôt qu'une mise à
  /// jour partielle — l'écran d'édition doit toujours pré-remplir puis
  /// renvoyer l'intégralité du formulaire.
  ///
  /// [photoPieceUrl] n'est pas éditable depuis le mobile (pièce scannée
  /// ajoutée depuis le web) : l'appelant doit transmettre la valeur actuelle
  /// du locataire pour qu'elle soit préservée, sinon elle serait effacée.
  Future<UpdateLocataireResult> update({
    required int id,
    required String nom,
    required String prenoms,
    required String telephonePrincipal,
    required String type,
    required String statut,
    required bool paiementEchelonne,
    String? email,
    String? telephoneSecondaire,
    String? nationalite,
    String? typePiece,
    String? numeroPiece,
    String? dateExpirationPiece,
    String? modePaiementPreferentiel,
    String? adresseActuelle,
    String? photoProfilUrl,
    String? photoPieceUrl,
  }) async {
    try {
      await _apiClient.request<Map<String, dynamic>>(
        '/locataires/$id',
        method: 'PUT',
        data: {
          'nom': nom,
          'prenoms': prenoms,
          'telephone_principal': telephonePrincipal,
          'type': type,
          'statut': statut,
          'paiement_echelonne': paiementEchelonne,
          'email': email,
          'telephone_secondaire': telephoneSecondaire,
          'nationalite': nationalite,
          'type_piece': typePiece,
          'numero_piece': numeroPiece,
          'date_expiration_piece': dateExpirationPiece,
          'mode_paiement_preferentiel': modePaiementPreferentiel,
          'adresse_actuelle': adresseActuelle,
          'photo_profil_url': photoProfilUrl,
          'photo_piece_url': photoPieceUrl,
        },
      );
      await refresh();
      return const UpdateLocataireSuccess();
    } on ApiException catch (e) {
      if (e.type == ApiExceptionType.validation) {
        return UpdateLocataireValidationFailed(e.message, e.fieldErrors);
      }
      return UpdateLocataireFailure(e.message, e.type);
    }
  }

  /// `DELETE /api/locataires/:id` — archivage (soft-delete vers la
  /// corbeille, voir `locataireRoutes.ts`). Suppression locale immédiate de
  /// [items] au succès (pas de champ calculé en jeu, contrairement à
  /// [create]/[update] : un simple retrait suffit, pas besoin de [refresh]).
  Future<DeleteLocataireResult> delete(int id) async {
    try {
      await _apiClient.request<void>('/locataires/$id', method: 'DELETE');
      _items = _items.where((l) => l.id != id).toList();
      notifyListeners();
      return const DeleteLocataireSuccess();
    } on ApiException catch (e) {
      return DeleteLocataireFailure(e.message, e.type);
    }
  }
}
