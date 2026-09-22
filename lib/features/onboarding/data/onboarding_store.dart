import 'package:shared_preferences/shared_preferences.dart';

/// Persiste si l'utilisateur a déjà terminé l'onboarding, pour ne plus
/// jamais le réafficher ensuite (y compris après une déconnexion ou une
/// session expirée — voir `AuthGate`).
///
/// Même pattern que `TokenStorage` : cache mémoire chargé une fois via
/// [load], lu de façon synchrone ensuite via [hasSeenOnboarding] —
/// nécessaire car `AuthGate.build()` est synchrone et ne peut pas attendre
/// une lecture disque à chaque rendu.
///
/// Singleton à constructeur privé (comme `ThemeController`/`LocaleController`,
/// `lib/core/theme`, `lib/core/i18n`) plutôt qu'un constructeur public à
/// dépendances explicites (contrairement à `TokenStorage`/`AuthRepository`) :
/// cette classe n'a aucune dépendance à injecter au niveau applicatif (elle
/// n'est utilisée que par `AuthGate`, jamais construite avec des paramètres
/// différents selon l'appelant) — les tests substituent le double du plugin
/// (`SharedPreferencesAsyncPlatform.instance`) plutôt que l'instance
/// elle-même.
class OnboardingStore {
  OnboardingStore._();

  static final OnboardingStore instance = OnboardingStore._();

  static const _key = 'onboarding_seen';

  bool _hasSeenOnboarding = false;

  bool get hasSeenOnboarding => _hasSeenOnboarding;

  // `SharedPreferencesAsync()` reconstruit à chaque appel plutôt que stocké
  // dans un champ : son constructeur capture `SharedPreferencesAsyncPlatform
  // .instance` au moment où il est appelé. Comme cette classe est un
  // singleton à durée de vie de l'app, un champ figerait ce double sur la
  // toute première valeur de `.instance` rencontrée — cassant les tests, qui
  // substituent ce double par test via `SharedPreferencesAsyncPlatform
  // .instance = ...` avant chaque appel à [load].
  Future<void> load() async {
    _hasSeenOnboarding = await SharedPreferencesAsync().getBool(_key) ?? false;
  }

  /// Marque l'onboarding comme vu. Idempotent : n'écrit sur le disque que la
  /// première fois.
  Future<void> markOnboardingSeen() async {
    if (_hasSeenOnboarding) return;
    _hasSeenOnboarding = true;
    await SharedPreferencesAsync().setBool(_key, true);
  }
}
