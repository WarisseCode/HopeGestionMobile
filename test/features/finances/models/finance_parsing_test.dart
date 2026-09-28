import 'package:flutter_test/flutter_test.dart';
import 'package:hope_gestion_mobile/features/finances/models/finance_parsing.dart';

void main() {
  group('asDateOrNull (colonnes DATE)', () {
    test('date simple prise telle quelle', () {
      expect(asDateOrNull('2026-09-15'), DateTime(2026, 9, 15));
    });

    test('instant ISO : jour de la date locale, sans heure', () {
      final attendu = DateTime.parse('2026-09-15T00:00:00.000Z').toLocal();
      expect(
        asDateOrNull('2026-09-15T00:00:00.000Z'),
        DateTime(attendu.year, attendu.month, attendu.day),
      );
    });

    test('valeurs invalides → null', () {
      expect(asDateOrNull(null), isNull);
      expect(asDateOrNull(''), isNull);
      expect(asDateOrNull('pas une date'), isNull);
      expect(asDateOrNull(42), isNull);
    });
  });

  group('asDoubleOrNull (colonnes NUMERIC)', () {
    test('chaîne, entier et double', () {
      expect(asDoubleOrNull('185000.00'), 185000);
      expect(asDoubleOrNull(185000), 185000);
      expect(asDoubleOrNull(12.5), 12.5);
      expect(asDoubleOrNull('abc'), isNull);
      expect(asDoubleOrNull(null), isNull);
    });
  });

  test('formatDateIso', () {
    expect(formatDateIso(DateTime(2026, 9, 1)), '2026-09-01');
  });
}
