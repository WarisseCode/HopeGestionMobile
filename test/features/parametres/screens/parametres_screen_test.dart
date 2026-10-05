import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hope_gestion_mobile/features/auth/screens/login_screen.dart';
import 'package:hope_gestion_mobile/features/onboarding/screens/onboarding_screen.dart';
import 'package:hope_gestion_mobile/features/parametres/screens/parametres_screen.dart';
import 'package:hope_gestion_mobile/features/profil/screens/change_password_screen.dart';

import '../../../support/mock_http_overrides.dart';

/// Paramètres ouvert par-dessus une page d'accueil fictive, comme dans
/// l'app (poussé depuis Profil).
Future<void> _pumpParametres(WidgetTester tester) async {
  // 720 dp de large : la police de test (Ahem, plus large que les vraies
  // polices) ferait déborder les en-têtes de l'onboarding et de
  // ChangePasswordScreen sur un écran de téléphone standard.
  tester.view.physicalSize = const Size(1440, 2400);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const ParametresScreen())),
            child: const Text('ouvrir'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('ouvrir'));
  await tester.pumpAndSettle();
  expect(find.byType(ParametresScreen), findsOneWidget);
}

Future<void> _openOnboarding(WidgetTester tester) async {
  final tile = find.text('Revoir la présentation');
  await tester.scrollUntilVisible(tile, 200);
  await tester.tap(tile);
  await tester.pumpAndSettle();
  expect(find.byType(OnboardingScreen), findsOneWidget);
}

void main() {
  setUpAll(() {
    HttpOverrides.global = MockHttpOverrides();
  });

  testWidgets('Revoir la présentation puis « Passer » : retour à Paramètres, '
      'sans écran de connexion', (tester) async {
    await _pumpParametres(tester);
    await _openOnboarding(tester);

    await tester.tap(find.text('Passer'));
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingScreen), findsNothing);
    expect(find.byType(LoginScreen), findsNothing);
    expect(find.byType(ParametresScreen), findsOneWidget);
  });

  testWidgets(
    'Revoir la présentation jusqu\'à la dernière page : retour à Paramètres, '
    'sans écran de connexion',
    (tester) async {
      await _pumpParametres(tester);
      await _openOnboarding(tester);

      // Bouton principal tapé jusqu'à sortir de l'onboarding (dernière page
      // incluse), quel que soit le nombre de pages.
      for (var i = 0; i < 10; i++) {
        if (find.byType(OnboardingScreen).evaluate().isEmpty) break;
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();
      }

      expect(find.byType(OnboardingScreen), findsNothing);
      expect(find.byType(LoginScreen), findsNothing);
      expect(find.byType(ParametresScreen), findsOneWidget);
    },
  );

  testWidgets('Changer de mot de passe : ouvre ChangePasswordScreen', (
    tester,
  ) async {
    await _pumpParametres(tester);

    expect(find.text('Dernière modification il y a 3 mois'), findsNothing);

    final tile = find.text('Changer de mot de passe');
    await tester.scrollUntilVisible(tile, 200);
    await tester.tap(tile);
    await tester.pumpAndSettle();

    expect(find.byType(ChangePasswordScreen), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
  });
}
