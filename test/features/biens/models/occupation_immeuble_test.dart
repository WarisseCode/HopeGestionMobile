import 'package:flutter_test/flutter_test.dart';
import 'package:hope_gestion_mobile/features/biens/models/lot.dart';
import 'package:hope_gestion_mobile/features/biens/models/occupation_immeuble.dart';

Lot _lot(String statut, {double? loyer, String? periodicite}) => Lot(
  id: 1,
  reference: 'A',
  statut: statut,
  loyer: loyer,
  periodicite: periodicite,
);

void main() {
  group('OccupationImmeuble', () {
    test('aucun lot créé → Vide à 0 %, même avec une capacité déclarée', () {
      final o = OccupationImmeuble.fromLots(const [], capacitePrevue: 20);

      expect(o.etat, 'Vide');
      expect(o.pourcentage, 0);
      expect(o.libelleCapacite, '0 lot créé · 20 prévus');
    });

    test('taux calculé sur les lots créés, pas sur la capacité', () {
      final o = OccupationImmeuble.fromLots([
        _lot('occupe'),
        _lot('disponible'),
      ], capacitePrevue: 20);

      expect(o.lotsOccupes, 1);
      expect(o.pourcentage, 50);
      expect(o.etat, 'En location');
    });

    test('loue / occupe / reserve comptent comme occupés (règle serveur)', () {
      final o = OccupationImmeuble.fromLots([
        _lot('loue'),
        _lot('occupe'),
        _lot('reserve'),
      ]);

      expect(o.etat, 'Complet');
      expect(o.pourcentage, 100);
    });

    test('lots tous libres → Disponible', () {
      expect(
        OccupationImmeuble.fromLots([_lot('disponible')]).etat,
        'Disponible',
      );
    });

    test('capacité égale ou absente : seulement les lots créés', () {
      expect(
        OccupationImmeuble.fromLots([
          _lot('occupe'),
        ], capacitePrevue: 1).libelleCapacite,
        '1 lot créé',
      );
      expect(
        OccupationImmeuble.fromLots([
          _lot('occupe'),
          _lot('occupe'),
        ], capacitePrevue: 0).libelleCapacite,
        '2 lots créés',
      );
    });

    test('revenu mensuel : loués/occupés seulement (pas les réservés), '
        'loyers mensualisés', () {
      final o = OccupationImmeuble.fromLots([
        _lot('occupe', loyer: 100000),
        _lot('reserve', loyer: 300000, periodicite: 'trimestriel'),
        _lot('loue', loyer: 1200000, periodicite: 'annuel'),
        _lot('loue', loyer: 600000, periodicite: 'semestriel'),
        _lot('disponible', loyer: 999999),
        _lot('occupe'),
      ]);

      // 100 000 (occupe) + 1 200 000 / 12 (loue, annuel) + 600 000 / 6
      // (loue, semestriel) ; le réservé et le disponible sont exclus.
      expect(o.revenuMensuel, 300000);
      // Le réservé compte toujours dans le taux d'occupation.
      expect(o.lotsOccupes, 5);
    });
  });
}
