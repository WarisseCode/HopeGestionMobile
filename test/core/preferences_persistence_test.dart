import 'package:flutter_test/flutter_test.dart';
import 'package:hope_gestion_mobile/core/i18n/locale_controller.dart';
import 'package:hope_gestion_mobile/core/theme/theme_controller.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// Persistance du thème et de la langue : un changement doit être relu par
/// une nouvelle instance du contrôleur (simule un redémarrage de l'app)
/// partageant le même stockage factice.
void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  group('ThemeController', () {
    test('sans valeur sauvegardée : thème clair par défaut', () async {
      final controller = ThemeController.forTesting();
      await controller.load();
      expect(controller.isDark, isFalse);
    });

    test('setDark(true) puis redémarrage : sombre relu', () async {
      await ThemeController.forTesting().setDark(true);

      final restarted = ThemeController.forTesting();
      await restarted.load();
      expect(restarted.isDark, isTrue);
    });

    test('retour au clair également persisté', () async {
      final first = ThemeController.forTesting();
      await first.setDark(true);
      await first.setDark(false);

      final restarted = ThemeController.forTesting();
      await restarted.load();
      expect(restarted.isDark, isFalse);
    });
  });

  group('LocaleController', () {
    test('sans valeur sauvegardée : français par défaut', () async {
      final controller = LocaleController.forTesting();
      await controller.load();
      expect(controller.language, AppLanguage.fr);
    });

    test('setLanguage(en) puis redémarrage : anglais relu', () async {
      await LocaleController.forTesting().setLanguage(AppLanguage.en);

      final restarted = LocaleController.forTesting();
      await restarted.load();
      expect(restarted.language, AppLanguage.en);
    });

    test('valeur inconnue sur disque : langue par défaut conservée', () async {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.withData({'app_language': 'de'});

      final controller = LocaleController.forTesting();
      await controller.load();
      expect(controller.language, AppLanguage.fr);
    });
  });
}
