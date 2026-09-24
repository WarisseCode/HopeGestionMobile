import 'package:flutter_test/flutter_test.dart';
import 'package:hope_gestion_mobile/features/biens/models/lot.dart';

void main() {
  group('Lot.mainPhoto', () {
    test('renvoie la première entrée de `photos` quand présente', () {
      final lot = Lot.fromJson({
        'id': 1,
        'reference': 'Apt. 12',
        'photos': [
          '/uploads/properties/a.jpg',
          '/uploads/properties/b.jpg',
        ],
      });

      expect(lot.mainPhoto, '/uploads/properties/a.jpg');
    });

    test('null quand `photos` est absent', () {
      final lot = Lot.fromJson({'id': 1, 'reference': 'Apt. 12'});

      expect(lot.mainPhoto, isNull);
    });

    test('null quand `photos` est un tableau vide', () {
      final lot = Lot.fromJson({
        'id': 1,
        'reference': 'Apt. 12',
        'photos': <dynamic>[],
      });

      expect(lot.mainPhoto, isNull);
    });
  });
}
