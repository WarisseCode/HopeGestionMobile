import 'package:flutter_test/flutter_test.dart';
import 'package:hope_gestion_mobile/features/biens/models/immeuble.dart';
import 'package:hope_gestion_mobile/features/biens/screens/biens_screen.dart';

void main() {
  group('BiensScreen.enteteLabel', () {
    test('somme des lots occupés / lots sur tous les immeubles', () {
      const immeubles = [
        Immeuble(id: 1, nom: 'A', nbLots: 3, lotsOccupes: 3),
        Immeuble(id: 2, nom: 'B', nbLots: 1, lotsOccupes: 0),
        Immeuble(id: 3, nom: 'C', nbLots: 4, lotsOccupes: 2),
      ];

      expect(
        BiensScreen.enteteLabel(immeubles),
        '3 IMMEUBLES · 5/8 LOTS OCCUPÉS',
      );
    });

    test('aucun lot (Z = 0) : seulement le nombre d\'immeubles', () {
      const immeubles = [
        Immeuble(id: 1, nom: 'A'),
        Immeuble(id: 2, nom: 'B'),
      ];

      expect(BiensScreen.enteteLabel(immeubles), '2 IMMEUBLES');
    });

    test('liste vide', () {
      expect(BiensScreen.enteteLabel(const []), '0 IMMEUBLES');
    });
  });
}
