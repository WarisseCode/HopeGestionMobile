import 'dart:io';

import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';

sealed class UploadPhotoResult {
  const UploadPhotoResult();
}

class UploadPhotoSuccess extends UploadPhotoResult {
  const UploadPhotoSuccess(this.path);

  /// Chemin/URL tel que renvoyé par le backend (`files[0].path`) — relatif
  /// tant que Digital Ocean Spaces n'est pas configuré en production (voir
  /// `AppConfig.resolveFileUrl`, appliqué uniquement à l'affichage, jamais
  /// ici : la valeur brute est ce que le backend attend en retour dans
  /// `photos`/`photo` à la création de l'immeuble).
  final String path;
}

class UploadPhotoFailure extends UploadPhotoResult {
  const UploadPhotoFailure(this.message);
  final String message;
}

/// `POST /api/upload` (`HopeGestionV2/backend/routes/uploadRoutes.ts`),
/// déjà authentifiée. `type: 'property'` correspond au dossier `properties`
/// résolu côté serveur (`resolveFolder`) — même convention que le web
/// (`ImageUpload.tsx`, `folder="property"`).
class PhotoUploadRepository {
  PhotoUploadRepository({required ApiClient apiClient})
    // ignore: prefer_initializing_formals
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<UploadPhotoResult> uploadPropertyPhoto(File file) async {
    try {
      final formData = FormData.fromMap({
        'type': 'property',
        'file': await MultipartFile.fromFile(file.path),
      });
      final response = await _apiClient.request<Map<String, dynamic>>(
        '/upload',
        method: 'POST',
        data: formData,
      );
      final files = response.data?['files'];
      if (files is! List || files.isEmpty) {
        throw const FormatException(
          'Réponse de /upload sans fichier exploitable.',
        );
      }
      final first = files.first;
      final path = first is Map ? first['path'] : null;
      if (path is! String) {
        throw const FormatException(
          'Réponse de /upload sans champ "path" exploitable.',
        );
      }
      return UploadPhotoSuccess(path);
    } on ApiException catch (e) {
      return UploadPhotoFailure(e.message);
    } on FormatException catch (e) {
      return UploadPhotoFailure(e.message);
    }
  }
}
