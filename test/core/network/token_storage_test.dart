import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hope_gestion_mobile/core/network/token_storage.dart';

void main() {
  // Double officiel du plugin (`flutter_secure_storage/test/...`) : un
  // stockage en mémoire derrière l'interface de plateforme, substitué au
  // canal de méthode réel (Keystore/Keychain). Le vrai plugin n'est jamais
  // appelé dans ces tests.
  late Map<String, String> backingStore;

  setUp(() {
    backingStore = {};
    FlutterSecureStoragePlatform.instance = TestFlutterSecureStoragePlatform(
      backingStore,
    );
  });

  test('savePair puis load : les tokens écrits sont relus depuis le stockage', () async {
    final writer = TokenStorage();
    await writer.savePair(
      const TokenPair(accessToken: 'access-1', refreshToken: 'refresh-1'),
    );

    // Nouvelle instance (simule un redémarrage de l'app) : rien en cache
    // tant que load() n'a pas été appelé.
    final reader = TokenStorage();
    expect(reader.accessToken, isNull);
    expect(reader.refreshToken, isNull);

    await reader.load();
    expect(reader.accessToken, 'access-1');
    expect(reader.refreshToken, 'refresh-1');
  });

  test('savePair met à jour le cache mémoire immédiatement, de façon cohérente', () async {
    final storage = TokenStorage();
    await storage.savePair(
      const TokenPair(accessToken: 'access-1', refreshToken: 'refresh-1'),
    );
    expect(storage.accessToken, 'access-1');
    expect(storage.refreshToken, 'refresh-1');

    // Simule un refresh : la nouvelle paire doit être visible en cache
    // (et déjà persistée) dès le retour de savePair, sans lecture
    // intermédiaire du stockage.
    await storage.savePair(
      const TokenPair(accessToken: 'access-2', refreshToken: 'refresh-2'),
    );
    expect(storage.accessToken, 'access-2');
    expect(storage.refreshToken, 'refresh-2');

    final reader = TokenStorage();
    await reader.load();
    expect(reader.accessToken, 'access-2');
    expect(reader.refreshToken, 'refresh-2');
  });

  test('clear efface le cache mémoire et le stockage sécurisé', () async {
    final storage = TokenStorage();
    await storage.savePair(
      const TokenPair(accessToken: 'access-1', refreshToken: 'refresh-1'),
    );

    await storage.clear();
    expect(storage.accessToken, isNull);
    expect(storage.refreshToken, isNull);

    final reader = TokenStorage();
    await reader.load();
    expect(reader.accessToken, isNull);
    expect(reader.refreshToken, isNull);
  });

  group('load — robustesse', () {
    test('JSON corrompu : cache null, stockage effacé, aucune exception', () async {
      backingStore['auth_token_pair'] = '{not valid json';

      final storage = TokenStorage();
      await storage.load(); // ne doit pas lancer

      expect(storage.accessToken, isNull);
      expect(storage.refreshToken, isNull);
      expect(backingStore.containsKey('auth_token_pair'), isFalse);
    });

    test('contenu JSON incomplet (clé manquante) : même traitement que corrompu', () async {
      backingStore['auth_token_pair'] = '{"access":"a-1"}'; // pas de "refresh"

      final storage = TokenStorage();
      await storage.load();

      expect(storage.accessToken, isNull);
      expect(storage.refreshToken, isNull);
      expect(backingStore.containsKey('auth_token_pair'), isFalse);
    });

    test('le stockage lève une exception en lecture : cache null, stockage effacé, aucune exception', () async {
      backingStore['auth_token_pair'] = 'peu importe, la lecture va échouer avant';
      FlutterSecureStoragePlatform.instance = _ThrowingReadPlatform(backingStore);

      final storage = TokenStorage();
      await storage.load(); // ne doit pas lancer

      expect(storage.accessToken, isNull);
      expect(storage.refreshToken, isNull);
      expect(backingStore.containsKey('auth_token_pair'), isFalse);
    });
  });

  group('savePairIfCurrent — course déconnexion / refresh', () {
    test('génération courante : écrit et renvoie true', () async {
      final storage = TokenStorage();

      final wrote = await storage.savePairIfCurrent(
        const TokenPair(accessToken: 'access-1', refreshToken: 'refresh-1'),
        storage.generation,
      );

      expect(wrote, isTrue);
      expect(storage.accessToken, 'access-1');
      expect(storage.refreshToken, 'refresh-1');

      final reader = TokenStorage();
      await reader.load();
      expect(reader.accessToken, 'access-1');
      expect(reader.refreshToken, 'refresh-1');
    });

    test('déconnexion puis génération obsolète : rien écrit, false, cache toujours null', () async {
      final storage = TokenStorage();
      final staleGeneration = storage.generation;

      await storage.clear(); // avance generation — simule une déconnexion pendant un refresh

      final wrote = await storage.savePairIfCurrent(
        const TokenPair(accessToken: 'access-2', refreshToken: 'refresh-2'),
        staleGeneration,
      );

      expect(wrote, isFalse);
      expect(storage.accessToken, isNull);
      expect(storage.refreshToken, isNull);
      expect(backingStore.containsKey('auth_token_pair'), isFalse);
    });
  });
}

/// Double qui simule un stockage sécurisé illisible (ex. clé Keystore
/// invalidée) : `read` lève, le reste (write/delete) reste fonctionnel en
/// mémoire pour pouvoir vérifier qu'un effacement a bien été tenté après.
class _ThrowingReadPlatform extends TestFlutterSecureStoragePlatform {
  _ThrowingReadPlatform(super.data);

  @override
  Future<String?> read({
    required String key,
    required Map<String, String> options,
  }) {
    throw Exception('Lecture du stockage sécurisé impossible (simulation de test).');
  }
}
