import 'package:flutter_test/flutter_test.dart';
import 'package:hope_gestion_mobile/features/biens/models/immeuble.dart';

void main() {
  group('Immeuble.mainPhoto', () {
    test('utilise `photo` quand présent', () {
      final immeuble = Immeuble.fromJson({
        'id': 1,
        'nom': 'Résidence Palmiers',
        'photo': 'https://cdn.example.com/main.jpg',
        'photos': ['https://cdn.example.com/a.jpg'],
      });

      expect(immeuble.mainPhoto, 'https://cdn.example.com/main.jpg');
    });

    test(
      'se rabat sur la première entrée de `photos` quand `photo` est null '
      '(cas réel : de nombreux immeubles créés côté web ont `photos` '
      'peuplé mais `photo_url` resté NULL en base)',
      () {
        final immeuble = Immeuble.fromJson({
          'id': 1,
          'nom': 'Résidence Palmiers',
          'photos': ['/uploads/properties/a.jpg', '/uploads/properties/b.jpg'],
        });

        expect(immeuble.mainPhoto, '/uploads/properties/a.jpg');
      },
    );

    test('null quand ni `photo` ni `photos` ne sont renseignés', () {
      final immeuble = Immeuble.fromJson({'id': 1, 'nom': 'Résidence Palmiers'});

      expect(immeuble.mainPhoto, isNull);
    });
  });
}
