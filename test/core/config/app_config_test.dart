import 'package:flutter_test/flutter_test.dart';
import 'package:hope_gestion_mobile/core/config/app_config.dart';

void main() {
  group('AppConfig.resolveFileUrl', () {
    test('préfixe un chemin relatif avec filesBaseUrl', () {
      final resolved = AppConfig.resolveFileUrl('/uploads/properties/x.jpg');

      expect(resolved, '${AppConfig.filesBaseUrl}/uploads/properties/x.jpg');
      expect(resolved, isNot(contains('/api/uploads')));
    });

    test('laisse une URL http déjà absolue inchangée', () {
      const absolute = 'http://cdn.example.com/uploads/x.jpg';
      expect(AppConfig.resolveFileUrl(absolute), absolute);
    });

    test('laisse une URL https déjà absolue inchangée', () {
      const absolute = 'https://bucket.fra1.digitaloceanspaces.com/x.jpg';
      expect(AppConfig.resolveFileUrl(absolute), absolute);
    });
  });

  group('AppConfig.filesBaseUrl', () {
    test('retire le suffixe /api de apiBaseUrl', () {
      expect(AppConfig.apiBaseUrl, endsWith('/api'));
      expect(AppConfig.filesBaseUrl, isNot(endsWith('/api')));
      expect(AppConfig.apiBaseUrl, '${AppConfig.filesBaseUrl}/api');
    });
  });
}
