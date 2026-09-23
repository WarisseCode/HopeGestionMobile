import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../models/owner.dart';
import 'locataire_results.dart';

/// `GET /api/owners` — propriétaires gérés par l'utilisateur connecté.
/// Utilisé uniquement pour alimenter le sélecteur "Propriétaire de
/// rattachement" du formulaire de création d'un locataire : pas d'état
/// partagé nécessaire, un simple appel à la demande (même choix que
/// `DashboardRepository`).
class OwnersRepository {
  OwnersRepository({required ApiClient apiClient})
    // ignore: prefer_initializing_formals
    : _apiClient = apiClient;

  final ApiClient _apiClient;

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
}
