import 'package:flutter_test/flutter_test.dart';
import 'package:hope_gestion_mobile/features/biens/models/immeuble.dart';
import 'package:hope_gestion_mobile/features/biens/models/immeubles_filtre.dart';

/// [etatServeur] volontairement contradictoire dans certains cas : les
/// filtres doivent suivre l'état calculé sur les lots créés, pas lui.
Immeuble _immeuble({
  required int lotsCrees,
  required int lotsOccupes,
  int capacite = 0,
  String? etatServeur,
}) => Immeuble(
  id: 1,
  nom: 'Test',
  nbLots: capacite > 0 ? capacite : lotsCrees,
  lotsCrees: lotsCrees,
  lotsOccupes: lotsOccupes,
  totalLotsDeclares: capacite,
  etatOccupation: etatServeur,
);

void main() {
  final vide = _immeuble(
    lotsCrees: 0,
    lotsOccupes: 0,
    capacite: 20,
    etatServeur: 'Disponible',
  );
  final disponible = _immeuble(lotsCrees: 2, lotsOccupes: 0);
  final enLocation = _immeuble(lotsCrees: 3, lotsOccupes: 1);
  final completSurLotsCrees = _immeuble(
    lotsCrees: 4,
    lotsOccupes: 4,
    capacite: 10,
    etatServeur: 'En location',
  );

  group('ImmeublesFiltre.matches (état calculé sur les lots créés)', () {
    test('Tous accepte tout', () {
      for (final i in [vide, disponible, enLocation, completSurLotsCrees]) {
        expect(ImmeublesFiltre.tous.matches(i), isTrue);
      }
    });

    test('Disponibles = au moins un lot libre (Disponible + En location)', () {
      expect(ImmeublesFiltre.disponibles.matches(disponible), isTrue);
      expect(ImmeublesFiltre.disponibles.matches(enLocation), isTrue);
      expect(ImmeublesFiltre.disponibles.matches(completSurLotsCrees), isFalse);
      expect(ImmeublesFiltre.disponibles.matches(vide), isFalse);
    });

    test('Complets : 4 lots créés tous occupés sur 10 prévus', () {
      expect(ImmeublesFiltre.complets.matches(completSurLotsCrees), isTrue);
      expect(ImmeublesFiltre.complets.matches(enLocation), isFalse);
    });

    test('Vides : aucun lot créé, même avec une capacité déclarée', () {
      expect(ImmeublesFiltre.vides.matches(vide), isTrue);
      expect(ImmeublesFiltre.vides.matches(disponible), isFalse);
    });
  });
}
