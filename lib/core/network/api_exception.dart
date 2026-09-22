import 'package:dio/dio.dart';

/// Catégorie d'échec normalisée, indépendante de Dio, que les écrans/
/// repositories peuvent utiliser pour décider comment réagir (message,
/// bouton "réessayer", redirection login...).
enum ApiExceptionType {
  /// Pas de réponse du serveur : pas de réseau, DNS, certificat, etc.
  network,

  /// Délai dépassé (connexion, envoi, réception).
  timeout,

  /// 401 : non authentifié, ou refresh refusé.
  unauthorized,

  /// 403 : authentifié mais non autorisé.
  forbidden,

  /// 404.
  notFound,

  /// 400 de validation (`express-validator`).
  validation,

  /// 429.
  rateLimited,

  /// 5xx.
  server,

  /// Tout le reste (statut inattendu, réponse mal formée, requête annulée...).
  unknown,
}

/// Erreur applicative uniforme levée par [ApiClient.request] à la place des
/// [DioException] brutes.
///
/// Ne contient jamais de token ni le corps de la requête d'origine — seul le
/// corps de la RÉPONSE d'erreur (déjà destiné à l'utilisateur/au
/// développeur par le backend) est inspecté pour construire [message] et
/// [fieldErrors].
class ApiException implements Exception {
  const ApiException({
    required this.type,
    required this.message,
    this.statusCode,
    this.fieldErrors = const {},
  });

  /// Construit une [ApiException] à partir d'une [DioException] Dio.
  factory ApiException.fromDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const ApiException(
          type: ApiExceptionType.timeout,
          message: 'La connexion a expiré. Réessayez.',
        );
      case DioExceptionType.connectionError:
        return const ApiException(
          type: ApiExceptionType.network,
          message: 'Connexion impossible. Vérifiez votre réseau.',
        );
      case DioExceptionType.badCertificate:
        return const ApiException(
          type: ApiExceptionType.network,
          message: 'Connexion sécurisée impossible.',
        );
      case DioExceptionType.cancel:
        return const ApiException(
          type: ApiExceptionType.unknown,
          message: 'Requête annulée.',
        );
      case DioExceptionType.badResponse:
        return _fromResponse(error.response);
      case DioExceptionType.unknown:
        // Certaines erreurs bas niveau (ex. SocketException selon la
        // plateforme) remontent avec ce type plutôt que `connectionError`.
        if (error.response != null) return _fromResponse(error.response);
        return const ApiException(
          type: ApiExceptionType.network,
          message: 'Connexion impossible. Vérifiez votre réseau.',
        );
    }
  }

  final ApiExceptionType type;
  final String message;
  final int? statusCode;

  /// `path` (nom de champ, format `express-validator`) → `msg`, pour un 400
  /// de validation. Vide si la réponse n'en contenait pas.
  final Map<String, String> fieldErrors;

  static ApiException _fromResponse(Response<dynamic>? response) {
    final statusCode = response?.statusCode;
    final data = response?.data;
    final extractedMessage = _extractMessage(data);
    final fieldErrors = _extractFieldErrors(data);

    switch (statusCode) {
      case 400:
        return ApiException(
          type: ApiExceptionType.validation,
          statusCode: statusCode,
          message: extractedMessage ?? 'Certaines informations sont invalides.',
          fieldErrors: fieldErrors,
        );
      case 401:
        return ApiException(
          type: ApiExceptionType.unauthorized,
          statusCode: statusCode,
          message: extractedMessage ?? 'Session expirée. Veuillez vous reconnecter.',
        );
      case 403:
        return ApiException(
          type: ApiExceptionType.forbidden,
          statusCode: statusCode,
          message: extractedMessage ?? 'Accès refusé.',
        );
      case 404:
        return ApiException(
          type: ApiExceptionType.notFound,
          statusCode: statusCode,
          message: extractedMessage ?? 'Ressource introuvable.',
        );
      case 429:
        return ApiException(
          type: ApiExceptionType.rateLimited,
          statusCode: statusCode,
          message: extractedMessage ?? 'Trop de requêtes. Réessayez dans un instant.',
        );
    }

    if (statusCode != null && statusCode >= 500) {
      return ApiException(
        type: ApiExceptionType.server,
        statusCode: statusCode,
        message: extractedMessage ?? 'Le serveur rencontre un problème. Réessayez plus tard.',
      );
    }

    return ApiException(
      type: ApiExceptionType.unknown,
      statusCode: statusCode,
      message: extractedMessage ?? 'Une erreur est survenue.',
      fieldErrors: fieldErrors,
    );
  }

  /// Ordre : `message`, puis `error` (ex. réponses 429), puis le premier
  /// `errors[].msg` (`express-validator`).
  static String? _extractMessage(dynamic data) {
    if (data is Map) {
      final message = data['message'];
      if (message is String && message.isNotEmpty) return message;

      final error = data['error'];
      if (error is String && error.isNotEmpty) return error;

      final errors = data['errors'];
      if (errors is List && errors.isNotEmpty) {
        final first = errors.first;
        if (first is Map) {
          final msg = first['msg'];
          if (msg is String && msg.isNotEmpty) return msg;
        }
      }
    }
    return null;
  }

  static Map<String, String> _extractFieldErrors(dynamic data) {
    if (data is Map) {
      final errors = data['errors'];
      if (errors is List) {
        final result = <String, String>{};
        for (final item in errors) {
          if (item is Map) {
            final path = item['path'];
            final msg = item['msg'];
            if (path is String && msg is String) {
              result[path] = msg;
            }
          }
        }
        return result;
      }
    }
    return const {};
  }

  @override
  String toString() =>
      'ApiException(type: $type, statusCode: $statusCode, message: $message)';
}
