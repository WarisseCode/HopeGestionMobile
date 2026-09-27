import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hope_gestion_mobile/core/design_system.dart';
import 'package:hope_gestion_mobile/core/theme/theme_controller.dart';
import 'package:hope_gestion_mobile/features/biens/models/immeuble.dart';
import 'package:hope_gestion_mobile/features/biens/widgets/immeuble_card.dart';

import '../../../support/mock_http_overrides.dart';

void main() {
  setUpAll(() => HttpOverrides.global = MockHttpOverrides());
  tearDown(() => ThemeController.instance.setDark(false));

  group('ImmeubleCard (rendu)', () {
    const long = Immeuble(
      id: 1,
      nom: 'Résidence des Palmiers au nom particulièrement long',
      type: 'Immeuble',
      ville: 'Cotonou',
      ownerName: 'Société Civile Immobilière Hope Investissements',
      nbLots: 3,
      lotsOccupes: 2,
      etatOccupation: 'En location',
    );

    for (final dark in [false, true]) {
      for (final photo in [null, '/uploads/properties/a.jpg']) {
        testWidgets(
          'sans débordement (sombre: $dark, photo: ${photo != null})',
          (tester) async {
            ThemeController.instance.setDark(dark);
            await tester.pumpWidget(
              MaterialApp(
                home: Scaffold(
                  body: Center(
                    child: SizedBox(
                      width: 320,
                      child: ImmeubleCard(
                        immeuble: Immeuble(
                          id: long.id,
                          nom: long.nom,
                          type: long.type,
                          ville: long.ville,
                          ownerName: long.ownerName,
                          nbLots: long.nbLots,
                          lotsOccupes: long.lotsOccupes,
                          etatOccupation: long.etatOccupation,
                          photo: photo,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
            await tester.pump();

            expect(tester.takeException(), isNull);
            expect(find.text('EN LOCATION'), findsOneWidget);
            expect(find.text('2 lots occupés sur 3'), findsOneWidget);
            expect(find.text(long.ownerName!), findsOneWidget);
            expect(
              tester.getSize(find.byType(ImmeubleCard)).height,
              greaterThanOrEqualTo(ImmeubleCard.minHeight),
            );
          },
        );
      }
    }
  });

  group('ImmeubleCard.occupationLabel', () {
    test('singulier pour 0 et 1 (règle française)', () {
      expect(ImmeubleCard.occupationLabel(0, 2), '0 lot occupé sur 2');
      expect(ImmeubleCard.occupationLabel(1, 3), '1 lot occupé sur 3');
    });

    test('pluriel à partir de 2', () {
      expect(ImmeubleCard.occupationLabel(2, 3), '2 lots occupés sur 3');
    });

    test('aucun lot déclaré', () {
      expect(ImmeubleCard.occupationLabel(0, 0), 'Aucun lot déclaré');
    });
  });

  group('EtatOccupationStyle.of', () {
    test('chaque état a sa couleur de badge', () {
      expect(
        EtatOccupationStyle.of('Complet').badgeType,
        AppBadgeType.positive,
      );
      expect(
        EtatOccupationStyle.of('En location').badgeType,
        AppBadgeType.info,
      );
      expect(
        EtatOccupationStyle.of('Disponible').badgeType,
        AppBadgeType.warning,
      );
      expect(EtatOccupationStyle.of('Vide').badgeType, AppBadgeType.neutral);
      expect(EtatOccupationStyle.of(null).label, 'Vide');
    });
  });
}
