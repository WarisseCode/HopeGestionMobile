import 'package:flutter_test/flutter_test.dart';
import 'package:hope_gestion_mobile/features/biens/models/immeuble.dart';
import 'package:hope_gestion_mobile/features/biens/screens/biens_screen.dart';

void main() {
  group('BiensScreen.enteteLabel', () {
    test('somme des lots occupés / lots créés sur tous les immeubles', () {
      const immeubles = [
        Immeuble(id: 1, nom: 'A', nbLots: 3, lotsCrees: 3, lotsOccupes: 3),
        Immeuble(id: 2, nom: 'B', nbLots: 1, lotsCrees: 1, lotsOccupes: 0),
        Immeuble(id: 3, nom: 'C', nbLots: 4, lotsCrees: 4, lotsOccupes: 2),
      ];

      expect(
        BiensScreen.enteteLabel(immeubles),
        '3 IMMEUBLES · 5/8 LOTS OCCUPÉS',
      );
    });

    test('Z = lots créés, pas la capacité déclarée (nbLots)', () {
      // 4 lots créés tous occupés sur 10 prévus : « Complet » sur la carte,
      // donc 4/4 dans l'en-tête (et non 4/10).
      const immeubles = [
        Immeuble(
          id: 1,
          nom: 'A',
          nbLots: 10,
          totalLotsDeclares: 10,
          lotsCrees: 4,
          lotsOccupes: 4,
        ),
        Immeuble(
          id: 2,
          nom: 'B',
          nbLots: 20,
          totalLotsDeclares: 20,
          lotsCrees: 2,
          lotsOccupes: 1,
        ),
      ];

      expect(
        BiensScreen.enteteLabel(immeubles),
        '2 IMMEUBLES · 5/6 LOTS OCCUPÉS',
      );
    });

    test('lotsCrees absent (backend antérieur) : repli sur nbLots', () {
      const immeubles = [Immeuble(id: 1, nom: 'A', nbLots: 3, lotsOccupes: 1)];

      expect(BiensScreen.enteteLabel(immeubles), '1 IMMEUBLES · 1/3 LOTS OCCUPÉS');
    });

    test('aucun lot (Z = 0) : seulement le nombre d\'immeubles', () {
      const immeubles = [
        Immeuble(id: 1, nom: 'A'),
        Immeuble(id: 2, nom: 'B'),
      ];

      expect(BiensScreen.enteteLabel(immeubles), '2 IMMEUBLES');
    });

    test('capacité déclarée mais aucun lot créé : Z = 0 aussi', () {
      const immeubles = [
        Immeuble(
          id: 1,
          nom: 'A',
          nbLots: 20,
          totalLotsDeclares: 20,
          lotsCrees: 0,
        ),
      ];

      expect(BiensScreen.enteteLabel(immeubles), '1 IMMEUBLES');
    });

    test('liste vide', () {
      expect(BiensScreen.enteteLabel(const []), '0 IMMEUBLES');
    });
  });
}
