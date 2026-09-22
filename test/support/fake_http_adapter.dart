import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Double HTTP minimal pour les tests Dio, piloté par une closure fournie
/// par chaque test. Pas de package de mock HTTP (`http_mock_adapter`
/// notamment, écarté en phase 2.1) : ce double suffit et évite une
/// dépendance supplémentaire pour un besoin aussi simple. Partagé entre
/// `test/core/network/api_client_test.dart` et
/// `test/features/auth/data/auth_repository_test.dart`.
class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this._responder);

  final Future<ResponseBody> Function(RequestOptions options) _responder;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) => _responder(options);

  @override
  void close({bool force = false}) {}
}

/// Construit une réponse JSON factice pour [FakeAdapter].
ResponseBody jsonResponse(Map<String, dynamic> body, int statusCode) {
  return ResponseBody.fromString(
    jsonEncode(body),
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

/// `Future.catchError` exige que le handler renvoie une valeur du même type
/// que le Future d'origine : impossible d'y renvoyer l'exception
/// elle-même quand elle diffère du type de succès. Capture proprement
/// succès/échec dans un seul type dynamique, pour un `Future.wait` de
/// requêtes dont certaines échouent.
Future<Object?> captureError(Future<Object?> Function() action) async {
  try {
    return await action();
  } catch (e) {
    return e;
  }
}
