import 'package:flutter_test/flutter_test.dart';
import 'package:hope_gestion_mobile/features/biens/models/immeuble.dart';
import 'package:hope_gestion_mobile/features/biens/models/immeubles_filtre.dart';

Immeuble _immeuble(String? etat) =>
    Immeuble(id: 1, nom: 'Test', etatOccupation: etat);

void main() {
  group('ImmeublesFiltre.matches', () {
    test('Tous accepte tous les états, y compris null', () {
      for (final etat in [
        'Vide',
        'Disponible',
        'En location',
        'Complet',
        null,
      ]) {
        expect(ImmeublesFiltre.tous.matches(_immeuble(etat)), isTrue);
      }
    });

    test('Disponibles = au moins un lot libre (Disponible + En location)', () {
      expect(
        ImmeublesFiltre.disponibles.matches(_immeuble('Disponible')),
        isTrue,
      );
      expect(
        ImmeublesFiltre.disponibles.matches(_immeuble('En location')),
        isTrue,
      );
      expect(
        ImmeublesFiltre.disponibles.matches(_immeuble('Complet')),
        isFalse,
      );
      expect(ImmeublesFiltre.disponibles.matches(_immeuble('Vide')), isFalse);
    });

    test('Complets = uniquement Complet', () {
      expect(ImmeublesFiltre.complets.matches(_immeuble('Complet')), isTrue);
      expect(
        ImmeublesFiltre.complets.matches(_immeuble('En location')),
        isFalse,
      );
    });

    test('Vides = Vide, ou état absent (même repli que le badge)', () {
      expect(ImmeublesFiltre.vides.matches(_immeuble('Vide')), isTrue);
      expect(ImmeublesFiltre.vides.matches(_immeuble(null)), isTrue);
      expect(ImmeublesFiltre.vides.matches(_immeuble('Disponible')), isFalse);
    });
  });
}
