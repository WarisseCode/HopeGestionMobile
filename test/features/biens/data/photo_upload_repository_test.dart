import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hope_gestion_mobile/core/network/api_client.dart';
import 'package:hope_gestion_mobile/core/network/token_storage.dart';
import 'package:hope_gestion_mobile/features/biens/data/photo_upload_repository.dart';

import '../../../support/fake_http_adapter.dart';

PhotoUploadRepository _repo(
  Future<ResponseBody> Function(RequestOptions options) responder,
) {
  final tokenStorage = TokenStorage();
  final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
    ..httpClientAdapter = FakeAdapter(responder);
  final apiClient = ApiClient(tokenStorage: tokenStorage, dio: dio);
  return PhotoUploadRepository(apiClient: apiClient);
}

void main() {
  setUp(() {
    FlutterSecureStoragePlatform.instance = TestFlutterSecureStoragePlatform(
      {},
    );
  });

  late File tempFile;

  setUpAll(() async {
    tempFile = File(
      '${Directory.systemTemp.path}/photo_upload_repository_test.jpg',
    );
    await tempFile.writeAsBytes([0xFF, 0xD8, 0xFF, 0xD9]);
  });

  tearDownAll(() async {
    if (await tempFile.exists()) await tempFile.delete();
  });

  test(
    'succès : envoie type=property + le fichier, renvoie le path renvoyé',
    () async {
      var postCalls = 0;
      final repo = _repo((options) async {
        expect(options.method, 'POST');
        expect(options.path, '/upload');
        expect(options.data, isA<FormData>());
        final formData = options.data as FormData;
        final typeField = formData.fields.firstWhere((f) => f.key == 'type');
        expect(typeField.value, 'property');
        expect(formData.files, hasLength(1));
        postCalls++;
        return jsonResponse({
          'message': 'Upload réussi',
          'files': [
            {'path': '/uploads/properties/167-abc123.jpg'},
          ],
        }, 200);
      });

      final result = await repo.uploadPropertyPhoto(tempFile);

      expect(result, isA<UploadPhotoSuccess>());
      expect(
        (result as UploadPhotoSuccess).path,
        '/uploads/properties/167-abc123.jpg',
      );
      expect(postCalls, 1);
    },
  );

  test('erreur serveur (500) → UploadPhotoFailure', () async {
    final repo = _repo(
      (options) async => jsonResponse({'message': 'Erreur lors de l\'upload'}, 500),
    );

    final result = await repo.uploadPropertyPhoto(tempFile);

    expect(result, isA<UploadPhotoFailure>());
    expect((result as UploadPhotoFailure).message, 'Erreur lors de l\'upload');
  });

  test('réponse 200 sans "files" exploitable → UploadPhotoFailure', () async {
    final repo = _repo(
      (options) async => jsonResponse({'message': 'Upload réussi', 'files': <dynamic>[]}, 200),
    );

    final result = await repo.uploadPropertyPhoto(tempFile);

    expect(result, isA<UploadPhotoFailure>());
  });
}
