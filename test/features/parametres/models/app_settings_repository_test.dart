import 'package:flutter_test/flutter_test.dart';
import 'package:hope_gestion_mobile/features/parametres/models/app_settings_repository.dart';

/// Valeurs par défaut déclarées dans `AppSettingsRepository`.
const _defaultNotifImpayes = true;
const _defaultNotifEcheances = true;
const _defaultNotifPush = true;
const _defaultBiometrie = false;

void main() {
  final settings = AppSettingsRepository.instance;

  // Singleton sans `initialize()` ni méthode de reset : l'état survit d'un
  // test à l'autre. On le remet aux valeurs par défaut via les champs publics
  // (affectation directe, pas de notification) après chaque test.
  tearDown(() {
    settings.notifImpayes = _defaultNotifImpayes;
    settings.notifEcheances = _defaultNotifEcheances;
    settings.notifPush = _defaultNotifPush;
    settings.biometrie = _defaultBiometrie;
  });

  // Chaque fichier de test tourne dans son propre isolate (singleton neuf) et
  // le tearDown ci-dessus restaure les valeurs par défaut après chaque test :
  // ce test reste valable quel que soit l'ordre d'exécution.
  test('état initial : notifications activées, biométrie désactivée', () {
    expect(settings.notifImpayes, isTrue);
    expect(settings.notifEcheances, isTrue);
    expect(settings.notifPush, isTrue);
    expect(settings.biometrie, isFalse);
  });

  test('instance : toujours le même objet (singleton)', () {
    expect(identical(AppSettingsRepository.instance, settings), isTrue);
  });

  test('instance : un changement est visible depuis tout accès au singleton', () {
    settings.setBiometrie(true);
    expect(AppSettingsRepository.instance.biometrie, isTrue);
  });

  group('setters : mettent à jour la valeur et notifient une fois', () {
    final cases = <String, (void Function(bool), bool Function())>{
      'setNotifImpayes': (settings.setNotifImpayes, () => settings.notifImpayes),
      'setNotifEcheances': (
        settings.setNotifEcheances,
        () => settings.notifEcheances,
      ),
      'setNotifPush': (settings.setNotifPush, () => settings.notifPush),
      'setBiometrie': (settings.setBiometrie, () => settings.biometrie),
    };

    cases.forEach((name, c) {
      final (setter, read) = c;
      test(name, () {
        var calls = 0;
        void listener() => calls++;
        settings.addListener(listener);
        addTearDown(() => settings.removeListener(listener));

        final initial = read();
        setter(!initial);
        expect(read(), !initial);
        expect(calls, 1);

        setter(initial);
        expect(read(), initial);
        expect(calls, 2);
      });
    });
  });

  test('setter : notifie même si la valeur ne change pas (pas de garde '
      "d'égalité dans le code actuel)", () {
    var calls = 0;
    void listener() => calls++;
    settings.addListener(listener);
    addTearDown(() => settings.removeListener(listener));

    settings.setNotifPush(settings.notifPush);
    settings.setBiometrie(settings.biometrie);

    expect(settings.notifPush, _defaultNotifPush);
    expect(settings.biometrie, _defaultBiometrie);
    expect(calls, 2);
  });

  test('setters : modifier un réglage ne touche pas aux autres', () {
    settings.setNotifImpayes(false);

    expect(settings.notifImpayes, isFalse);
    expect(settings.notifEcheances, _defaultNotifEcheances);
    expect(settings.notifPush, _defaultNotifPush);
    expect(settings.biometrie, _defaultBiometrie);
  });
}
