import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/screens/shell_screen.dart';
import '../../onboarding/data/onboarding_store.dart';
import '../../onboarding/screens/onboarding_screen.dart';
import '../data/auth_repository.dart';
import '../data/auth_state.dart';
import '../widgets/auth_widgets.dart';
import 'login_screen.dart';
import 'offline_screen.dart';
import 'unsupported_role_screen.dart';

/// Racine réactive de l'app : affiche l'écran adapté à
/// `AuthRepository.instance.state` et le tient à jour à chaque changement
/// (`ListenableBuilder`, cohérent avec `ThemeController`/`ProfilScreen`).
///
/// Recentre aussi la pile de navigation sur cette route à chaque changement
/// d'état (ex. déconnexion ou session expirée depuis un écran poussé
/// par-dessus, comme `ProfilScreen`) : sans ça, cet écran poussé resterait
/// affiché par-dessus le nouvel écran racine. C'est pour la même raison que
/// `OnboardingScreen`/`LoginScreen`/`RegisterScreen` ne font plus de
/// `Navigator.pushReplacement` vers l'écran suivant du flux — ça
/// remplacerait cette route elle-même.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    AuthRepository.instance.addListener(_onAuthChanged);
  }

  void _onAuthChanged() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    });
  }

  @override
  void dispose() {
    AuthRepository.instance.removeListener(_onAuthChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AuthRepository.instance,
      builder: (context, _) {
        return switch (AuthRepository.instance.state) {
          AuthInitializing() => const _AuthLoadingScreen(),
          AuthOffline() => const OfflineScreen(),
          AuthUnsupportedRole() => const UnsupportedRoleScreen(),
          AuthUnauthenticated(message: final message) => _UnauthenticatedFlow(
            message: message,
          ),
          AuthAuthenticated() => const ShellScreen(),
        };
      },
    );
  }
}

class _AuthLoadingScreen extends StatelessWidget {
  const _AuthLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFEAF7F5),
      body: Center(child: CircularProgressIndicator(color: kTeal)),
    );
  }
}

/// Onboarding (une seule fois, jamais réaffiché ensuite — voir
/// `OnboardingStore`) puis connexion. La transition vers l'écran de
/// connexion se fait par un changement d'état LOCAL à ce widget (`onDone`),
/// pas via le Navigator racine, pour laisser `AuthGate` seul propriétaire de
/// cette route.
class _UnauthenticatedFlow extends StatefulWidget {
  const _UnauthenticatedFlow({this.message});

  final String? message;

  @override
  State<_UnauthenticatedFlow> createState() => _UnauthenticatedFlowState();
}

class _UnauthenticatedFlowState extends State<_UnauthenticatedFlow> {
  late bool _showLogin = OnboardingStore.instance.hasSeenOnboarding;

  void _onOnboardingDone() {
    // Marqué "vu" à la FIN du carrousel (pas dès son premier affichage) :
    // si l'app est tuée avant que l'utilisateur ait terminé ou tapé
    // "Passer", il doit revoir l'onboarding au prochain lancement plutôt que
    // le manquer définitivement pour ne l'avoir qu'entraperçu.
    unawaited(OnboardingStore.instance.markOnboardingSeen());
    setState(() => _showLogin = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_showLogin) {
      return LoginScreen(message: widget.message);
    }
    return OnboardingScreen(onDone: _onOnboardingDone);
  }
}
