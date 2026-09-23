import 'dart:async';

import 'package:flutter/material.dart';

import 'core/design_system.dart';
import 'core/network/api_client.dart';
import 'core/network/token_storage.dart';
import 'core/theme/theme_controller.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/screens/auth_gate.dart';
import 'features/biens/data/biens_repository.dart';
import 'features/locataires/data/locataires_repository.dart';
import 'features/onboarding/data/onboarding_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Chargé avant runApp : `AuthGate` peut atteindre l'état `unauthenticated`
  // dès la première frame (aucun token, restoreSession() se résout sans
  // attente réseau), donc `OnboardingStore.instance.hasSeenOnboarding`
  // (lu de façon synchrone par `AuthGate`) doit déjà refléter le disque à
  // ce moment-là.
  await OnboardingStore.instance.load();

  // Un seul TokenStorage/ApiClient/AuthRepository pour toute l'app (accès
  // global via `AuthRepository.instance`, voir sa doc de classe). Le cache
  // mémoire de TokenStorage doit être chargé avant tout appel authentifié
  // — donc avant runApp, pour qu'aucun écran ne puisse démarrer une requête
  // avec un cache vide alors qu'une session existe sur disque.
  final tokenStorage = TokenStorage();
  await tokenStorage.load();
  final apiClient = ApiClient(tokenStorage: tokenStorage);
  AuthRepository.initialize(
    AuthRepository(apiClient: apiClient, tokenStorage: tokenStorage),
  );
  // Réutilise le même ApiClient authentifié (voir AuthRepository.apiClient)
  // plutôt qu'une seconde instance Dio parallèle.
  LocatairesRepository.initialize(
    LocatairesRepository(apiClient: apiClient),
  );
  BiensRepository.initialize(
    BiensRepository(apiClient: apiClient),
  );
  // Non attendu : AuthGate (voir plus bas) affiche un écran de chargement
  // pendant que restoreSession() tourne, pas la peine de bloquer runApp.
  unawaited(AuthRepository.instance.restoreSession());

  runApp(const HopeGestionApp());
}

class HopeGestionApp extends StatelessWidget {
  final Widget? home;

  const HopeGestionApp({super.key, this.home});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) {
        return MaterialApp(
          title: 'HopeGestion Mobile',
          debugShowCheckedModeBanner: false,
          showPerformanceOverlay: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeController.instance.themeMode,
          // Flow par défaut : AuthGate décide entre chargement, hors-ligne,
          // onboarding → connexion, rôle non supporté ou shell, selon
          // AuthRepository.instance.state.
          home: home ?? const AuthGate(),
        );
      },
    );
  }
}
