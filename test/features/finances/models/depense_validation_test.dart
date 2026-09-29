import 'package:flutter_test/flutter_test.dart';
import 'package:hope_gestion_mobile/features/finances/models/depense_validation.dart';

void main() {
  group('validerMontantDepense', () {
    test('nul, négatif ou absent refusé', () {
      expect(validerMontantDepense(0), contains('supérieur à 0'));
      expect(validerMontantDepense(-100), contains('supérieur à 0'));
      expect(validerMontantDepense(null), contains('supérieur à 0'));
    });

    test('positif accepté', () {
      expect(validerMontantDepense(45000), isNull);
    });
  });

  group('validerDateDepense', () {
    final aujourdhui = DateTime(2026, 9, 28);

    test('date future refusée', () {
      expect(
        validerDateDepense(DateTime(2026, 9, 29), aujourdhui),
        contains('futur'),
      );
    });

    test('aujourd\'hui accepté', () {
      expect(validerDateDepense(aujourdhui, aujourdhui), isNull);
    });

    test('date passée acceptée', () {
      expect(validerDateDepense(DateTime(2026, 1, 1), aujourdhui), isNull);
    });

    test('compare le jour civil, pas l\'heure', () {
      final aujourdhuiSoir = DateTime(2026, 9, 28, 23, 59);
      expect(validerDateDepense(aujourdhui, aujourdhuiSoir), isNull);
    });
  });

  group('validerTailleJustificatif', () {
    test('sous la limite (10 Mo) accepté', () {
      expect(validerTailleJustificatif(tailleMaxJustificatifOctets), isNull);
      expect(validerTailleJustificatif(1024), isNull);
    });

    test('au-delà de la limite refusé', () {
      expect(
        validerTailleJustificatif(tailleMaxJustificatifOctets + 1),
        contains('10 Mo'),
      );
    });
  });
}
