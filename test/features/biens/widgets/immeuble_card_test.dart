import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hope_gestion_mobile/core/design_system.dart';
import 'package:hope_gestion_mobile/core/theme/theme_controller.dart';
import 'package:hope_gestion_mobile/features/biens/models/immeuble.dart';
import 'package:hope_gestion_mobile/features/biens/models/lot.dart';
import 'package:hope_gestion_mobile/features/biens/models/occupation_immeuble.dart';
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
            // `lotsCrees` absent → repli sur `nbLots` (3).
            expect(find.text('3 lots créés'), findsOneWidget);
            expect(find.text('67 %'), findsOneWidget);
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

  group('Cohérence carte / fiche (OccupationRegles)', () {
    // 4 lots créés tous occupés sur 10 prévus : le serveur dit
    // « En location » (calcul sur la capacité), carte et fiche « Complet ».
    const immeuble = Immeuble(
      id: 1,
      nom: 'Résidence',
      nbLots: 10,
      lotsCrees: 4,
      lotsOccupes: 4,
      totalLotsDeclares: 10,
      etatOccupation: 'En location',
    );
    final lots = [
      for (var i = 1; i <= 4; i++)
        Lot(id: i, reference: 'A$i', buildingId: 1, statut: 'occupe'),
    ];

    test('même état, même libellé, même taux', () {
      final fiche = OccupationImmeuble.fromLots(lots, capacitePrevue: 10);

      expect(immeuble.etat, 'Complet');
      expect(fiche.etat, immeuble.etat);
      expect(fiche.libelleCapacite, immeuble.libelleCapacite);
      expect(immeuble.libelleCapacite, '4 lots créés · 10 prévus');
      expect(fiche.pourcentage, immeuble.pourcentageOccupation);
    });

    testWidgets('la carte affiche Complet, pas l\'état serveur', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ImmeubleCard(immeuble: immeuble)),
        ),
      );

      expect(find.text('COMPLET'), findsOneWidget);
      expect(find.text('EN LOCATION'), findsNothing);
      expect(find.text('4 lots créés · 10 prévus'), findsOneWidget);
      expect(find.text('100 %'), findsOneWidget);
    });

    testWidgets('aucun lot créé, 20 prévus : Vide (libellé de la fiche)', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ImmeubleCard(
              immeuble: Immeuble(
                id: 2,
                nom: 'Projet',
                nbLots: 20,
                lotsCrees: 0,
                totalLotsDeclares: 20,
                etatOccupation: 'Disponible',
              ),
            ),
          ),
        ),
      );

      expect(find.text('VIDE'), findsOneWidget);
      expect(find.text('0 lot créé · 20 prévus'), findsOneWidget);
    });

    testWidgets('propriétaire en « Prénom Nom » (ownerNomAffiche)', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ImmeubleCard(
              immeuble: Immeuble(
                id: 3,
                nom: 'A',
                ownerName: 'CAMARA Mamadou',
                ownerNom: 'CAMARA',
                ownerPrenom: 'Mamadou',
                ownerType: 'individual',
              ),
            ),
          ),
        ),
      );

      expect(find.text('Mamadou CAMARA'), findsOneWidget);
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
