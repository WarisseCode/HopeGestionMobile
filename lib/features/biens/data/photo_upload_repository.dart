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
/// déjà authentifiée. Générique aux modules qui en ont besoin (Biens,
/// Locataires — voir `resolveFolder` côté serveur) : le `type` détermine
/// le dossier de destination, même convention que le web (`ImageUpload
/// .tsx`, prop `folder`).
///
/// Pas d'état partagé entre écrans (contrairement à `AuthRepository`) : chaque
/// upload est une opération ponctuelle et sans cache, dont seul le widget
/// appelant (`PhotosPicker`, `AvatarPicker`) consomme le résultat avant de le
/// remonter à son formulaire. Il n'y a donc rien à exposer en
/// `ChangeNotifier` ni à garder dans une instance statique : chaque widget
/// crée sa propre instance avec l'`ApiClient` partagé
/// (`AuthRepository.instance.apiClient`).
class PhotoUploadRepository {
  PhotoUploadRepository({required ApiClient apiClient})
    // ignore: prefer_initializing_formals
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// `type: 'property'` → dossier `properties`.
  Future<UploadPhotoResult> uploadPropertyPhoto(File file) =>
      _upload('property', file);

  /// `type: 'avatar'` → dossier `avatars` — photo de profil d'un locataire
  /// (`Locataire.photoProfilUrl`), même convention que le web
  /// (`AvatarUpload.tsx`).
  Future<UploadPhotoResult> uploadAvatarPhoto(File file) =>
      _upload('avatar', file);

  Future<UploadPhotoResult> _upload(String type, File file) async {
    try {
      final formData = FormData.fromMap({
        'type': type,
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
