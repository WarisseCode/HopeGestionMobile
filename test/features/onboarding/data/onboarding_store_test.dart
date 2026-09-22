import 'package:flutter_test/flutter_test.dart';
import 'package:hope_gestion_mobile/features/onboarding/data/onboarding_store.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  test('load() sans donnée existante : hasSeenOnboarding = false', () async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();

    await OnboardingStore.instance.load();

    expect(OnboardingStore.instance.hasSeenOnboarding, isFalse);
  });

  test('load() avec onboarding_seen=true : hasSeenOnboarding = true', () async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.withData({'onboarding_seen': true});

    await OnboardingStore.instance.load();

    expect(OnboardingStore.instance.hasSeenOnboarding, isTrue);
  });

  test(
    'markOnboardingSeen() écrit sur le stockage (pas seulement le cache), '
    'relu par un load() ultérieur',
    () async {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
      await OnboardingStore.instance.load();
      expect(OnboardingStore.instance.hasSeenOnboarding, isFalse);

      await OnboardingStore.instance.markOnboardingSeen();
      expect(OnboardingStore.instance.hasSeenOnboarding, isTrue);

      // Un nouveau load() (ex. prochain lancement de l'app) doit retrouver
      // `true` depuis le stockage : si markOnboardingSeen() n'avait mis à
      // jour que le cache mémoire sans écrire sur le disque, ce load()
      // repartirait à `false`.
      await OnboardingStore.instance.load();
      expect(OnboardingStore.instance.hasSeenOnboarding, isTrue);
    },
  );
}
