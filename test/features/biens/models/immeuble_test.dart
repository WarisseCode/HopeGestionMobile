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

  group('Immeuble (fiche détail)', () {
    test('totalLotsDeclares lit la colonne brute total_lots', () {
      final immeuble = Immeuble.fromJson({
        'id': 1,
        'nom': 'A',
        'total_lots': '20',
        'nbLots': 20,
      });

      expect(immeuble.totalLotsDeclares, 20);
    });

    test('lotsCrees lu depuis la réponse (backend ≥ T-005)', () {
      final immeuble = Immeuble.fromJson({
        'id': 1,
        'nom': 'A',
        'nbLots': 20,
        'lotsCrees': 4,
        'lotsOccupes': 4,
        'total_lots': 20,
      });

      expect(immeuble.lotsCrees, 4);
      expect(immeuble.etat, 'Complet');
    });

    test('lotsCrees absent (backend antérieur) → repli sur nbLots', () {
      final immeuble = Immeuble.fromJson({
        'id': 1,
        'nom': 'A',
        'nbLots': 3,
        'lotsOccupes': 1,
      });

      expect(immeuble.lotsCrees, 3);
      expect(immeuble.etat, 'En location');
    });

    test('galerie : photo principale en tête, sans doublon ni vide', () {
      final immeuble = Immeuble.fromJson({
        'id': 1,
        'nom': 'A',
        'photo': '/b.jpg',
        'photos': ['/a.jpg', '/b.jpg', ''],
      });

      expect(immeuble.galerie, ['/b.jpg', '/a.jpg']);
    });

    test('ownerNomAffiche : « Prénom Nom » pour un particulier', () {
      final immeuble = Immeuble.fromJson({
        'id': 1,
        'nom': 'A',
        'proprietaire': 'CAMARA Mamadou',
        'owner_name': 'CAMARA',
        'owner_first_name': 'Mamadou',
        'owner_type': 'individual',
      });

      expect(immeuble.ownerNomAffiche, 'Mamadou CAMARA');
    });

    test('ownerNomAffiche : raison sociale inchangée', () {
      final immeuble = Immeuble.fromJson({
        'id': 1,
        'nom': 'A',
        'proprietaire': 'SCI Hope',
        'owner_name': 'SCI Hope',
        'owner_type': 'company',
      });

      expect(immeuble.ownerNomAffiche, 'SCI Hope');
    });
  });
}
