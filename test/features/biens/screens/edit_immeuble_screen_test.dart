import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hope_gestion_mobile/core/network/api_client.dart';
import 'package:hope_gestion_mobile/core/network/token_storage.dart';
import 'package:hope_gestion_mobile/core/theme/theme_controller.dart';
import 'package:hope_gestion_mobile/features/biens/data/biens_repository.dart';
import 'package:hope_gestion_mobile/features/biens/models/immeuble.dart';
import 'package:hope_gestion_mobile/features/biens/screens/edit_immeuble_screen.dart';
import 'package:hope_gestion_mobile/features/biens/widgets/photos_picker.dart';

import '../../../support/fake_http_adapter.dart';
import '../../../support/mock_http_overrides.dart';

Immeuble _immeuble({required bool withPhotos}) => Immeuble(
  id: 5,
  nom: 'Résidence des Palmiers au nom particulièrement long',
  type: 'Immeuble',
  adresse: 'Rue 12.345, lot 67',
  quartier: 'Haie Vive',
  ville: 'Cotonou',
  pays: 'Bénin',
  description: 'Immeuble R+3 proche du marché.',
  photo: withPhotos ? '/uploads/properties/main.jpg' : null,
  photos: withPhotos
      ? const ['/uploads/properties/main.jpg', '/uploads/properties/b.jpg']
      : const [],
  videoUrl: 'https://video.test/v.mp4',
  planMasseUrl: '/uploads/plans/p.pdf',
  latitude: 6.36,
  longitude: 2.42,
  nombreEtages: 0,
  totalLotsDeclares: 20,
  ownerId: 3,
  gestionnaireId: 12,
);

void main() {
  setUpAll(() => HttpOverrides.global = MockHttpOverrides());
  setUp(() {
    FlutterSecureStoragePlatform.instance = TestFlutterSecureStoragePlatform(
      {},
    );
  });
  tearDown(() => ThemeController.instance.setDark(false));

  /// Initialise le dépôt sur un faux serveur ; renvoie une fonction qui lit
  /// le dernier corps reçu par `POST /biens/immeubles`.
  Map? Function() fakeServer() {
    Map? sent;
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = FakeAdapter((options) async {
        if (options.method == 'POST' && options.path == '/biens/immeubles') {
          sent = options.data as Map;
          return jsonResponse({'id': 5}, 200);
        }
        if (options.method == 'GET' && options.path == '/biens/immeubles') {
          return jsonResponse({'immeubles': <dynamic>[]}, 200);
        }
        throw UnimplementedError('${options.method} ${options.path}');
      });
    BiensRepository.initialize(
      BiensRepository(
        apiClient: ApiClient(tokenStorage: TokenStorage(), dio: dio),
      ),
    );
    return () => sent;
  }

  Future<void> pump(
    WidgetTester tester, {
    required bool dark,
    required bool withPhotos,
  }) async {
    // Hauteur généreuse : la `ListView` ne construit que ce qui est visible.
    tester.view.physicalSize = const Size(390, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    ThemeController.instance.setDark(dark);

    await tester.pumpWidget(
      MaterialApp(
        home: EditImmeubleScreen(immeuble: _immeuble(withPhotos: withPhotos)),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final dark in [false, true]) {
    for (final withPhotos in [false, true]) {
      testWidgets(
        'rendu pré-rempli sans débordement (sombre: $dark, photos: $withPhotos)',
        (tester) async {
          fakeServer();
          await pump(tester, dark: dark, withPhotos: withPhotos);

          expect(tester.takeException(), isNull);
          expect(
            find.text('Résidence des Palmiers au nom particulièrement long'),
            findsOneWidget,
          );
          expect(find.text('Cotonou'), findsOneWidget);
          expect(find.text('20'), findsOneWidget); // capacité prévue
          expect(find.text(withPhotos ? '2/10' : '0/10'), findsOneWidget);
          expect(find.text('Enregistrer'), findsOneWidget);
        },
      );
    }
  }

  testWidgets(
    'Enregistrer renvoie les champs non éditables tels quels, dont owner_id',
    (tester) async {
      final sent = fakeServer();
      await pump(tester, dark: false, withPhotos: true);

      await tester.enterText(
        find.widgetWithText(TextField, 'Cotonou'),
        'Porto-Novo',
      );
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();

      final body = sent()!;
      expect(body['id'], 5);
      expect(body['ville'], 'Porto-Novo');
      // Non éditables à l'écran : valeur actuelle renvoyée.
      expect(body['owner_id'], 3);
      expect(body['gestionnaire_id'], 12);
      expect(body['latitude'], 6.36);
      expect(body['longitude'], 2.42);
      expect(body['video_url'], 'https://video.test/v.mp4');
      expect(body['plan_masse_url'], '/uploads/plans/p.pdf');
      // Éditables non modifiés : valeur actuelle, 0 étage conservé.
      expect(body['nombre_etages'], 0);
      expect(body['total_lots'], 20);
      expect(body['statut'], 'actif');
      expect(body['photos'], [
        '/uploads/properties/main.jpg',
        '/uploads/properties/b.jpg',
      ]);
      expect(body['photo'], '/uploads/properties/main.jpg');
    },
  );

  testWidgets('nom vide : erreur locale, aucun envoi', (tester) async {
    final sent = fakeServer();
    await pump(tester, dark: false, withPhotos: false);

    await tester.enterText(
      find.widgetWithText(
        TextField,
        'Résidence des Palmiers au nom particulièrement long',
      ),
      '',
    );
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    expect(find.text('Le nom et la ville sont obligatoires.'), findsOneWidget);
    expect(sent(), isNull);
  });

  testWidgets('supprimer une photo la retire de l\'envoi', (tester) async {
    final sent = fakeServer();
    await pump(tester, dark: false, withPhotos: true);

    // Pastille de suppression de la première photo (icône x du sélecteur).
    await tester.tap(
      find
          .descendant(
            of: find.byType(PhotosPicker),
            matching: find.byIcon(LucideIcons.x),
          )
          .first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    final body = sent()!;
    expect(body['photos'], ['/uploads/properties/b.jpg']);
    expect(body['photo'], '/uploads/properties/b.jpg');
  });
}
