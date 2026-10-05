import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../models/owner.dart';
import 'locataire_results.dart';

/// `GET /api/owners` et `GET /api/owners/:id` — propriétaires gérés par
/// l'utilisateur connecté.
///
/// Deux usages coexistent, même classe :
/// - [instance] (initialisée dans `main.dart`) : état partagé [items],
///   alimenté par [refresh], écouté par l'onglet Propriétaires de
///   `LocatairesScreen` ;
/// - instances locales (`NouveauLocataireScreen`, `NouveauBienScreen`,
///   `DepenseScreen`) : n'appellent que [list], appel ponctuel sans état
///   partagé pour alimenter un sélecteur — [list] ne modifie jamais [items].
///
/// `GET /api/owners/:id/properties` n'est volontairement pas exposé : la
/// route backend ne filtre pas la corbeille et écrase `total_lots` (collision
/// de nom de colonne). Les biens d'un propriétaire sont filtrés côté client
/// depuis `BiensRepository.immeubles` (voir `OwnerDetailScreen`).
class OwnersRepository extends ChangeNotifier {
  OwnersRepository({required ApiClient apiClient})
    // ignore: prefer_initializing_formals
    : _apiClient = apiClient;

  static OwnersRepository? _instance;

  static OwnersRepository get instance {
    final current = _instance;
    if (current == null) {
      throw StateError(
        'OwnersRepository.instance accédée avant OwnersRepository.initialize().',
      );
    }
    return current;
  }

  static void initialize(OwnersRepository repository) {
    _instance = repository;
  }

  final ApiClient _apiClient;

  List<Owner> _items = [];

  List<Owner> get items => List.unmodifiable(_items);

  /// Lecture ponctuelle, sans effet sur [items].
  Future<OwnersListResult> list() async {
    try {
      final response = await _apiClient.request<Map<String, dynamic>>(
        '/owners',
      );
      final raw = response.data?['owners'];
      if (raw is! List) {
        throw const FormatException(
          'Réponse de /owners sans champ "owners" exploitable.',
        );
      }
      final owners = raw
          .whereType<Map<String, dynamic>>()
          .map(Owner.fromJson)
          .toList();
      return OwnersListSuccess(owners);
    } on ApiException catch (e) {
      return OwnersListFailure(e.message, e.type);
    } on FormatException catch (e) {
      return OwnersListFailure(e.message, ApiExceptionType.unknown);
    }
  }

  /// [list] puis mise à jour de [items] au succès ; en cas d'échec, [items]
  /// garde sa dernière valeur connue (même politique que
  /// `LocatairesRepository.refresh`).
  Future<OwnersListResult> refresh() async {
    final result = await list();
    if (result is OwnersListSuccess) {
      _items = result.owners;
      notifyListeners();
    }
    return result;
  }

  /// `GET /api/owners/:id` — ne touche pas à [items]. La réponse ne contient
  /// pas les compteurs (`total_properties`/`total_lots`), ni ne sont
  /// nécessaires : la fiche compte les biens depuis `BiensRepository`.
  Future<OwnerDetailResult> getDetail(int id) async {
    try {
      final response = await _apiClient.request<Map<String, dynamic>>(
        '/owners/$id',
      );
      final raw = response.data?['owner'];
      if (raw is! Map<String, dynamic>) {
        throw const FormatException(
          'Réponse de /owners/:id sans champ "owner" exploitable.',
        );
      }
      return OwnerDetailSuccess(Owner.fromJson(raw));
    } on ApiException catch (e) {
      return OwnerDetailFailure(e.message, e.type);
    } on FormatException catch (e) {
      return OwnerDetailFailure(e.message, ApiExceptionType.unknown);
    }
  }
}
