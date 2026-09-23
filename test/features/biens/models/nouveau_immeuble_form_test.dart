import 'package:flutter_test/flutter_test.dart';
import 'package:hope_gestion_mobile/features/biens/models/nouveau_immeuble_form.dart';

void main() {
  group('NouveauImmeubleForm.isStep2Valid', () {
    test(
      'adresse vide bloque la progression même si la ville est renseignée '
      '(buildings.adresse est NOT NULL — voir db/init.sql)',
      () {
        final form = NouveauImmeubleForm()
          ..adresse = ''
          ..ville = 'Cotonou';

        expect(form.isStep2Valid(), isFalse);
      },
    );

    test('ville vide bloque la progression même si l\'adresse est renseignée', () {
      final form = NouveauImmeubleForm()
        ..adresse = '123 Rue de la Paix'
        ..ville = '';

      expect(form.isStep2Valid(), isFalse);
    });

    test('adresse et ville renseignées valident l\'étape', () {
      final form = NouveauImmeubleForm()
        ..adresse = '123 Rue de la Paix'
        ..ville = 'Cotonou';

      expect(form.isStep2Valid(), isTrue);
    });

    test('un espace seul n\'est pas considéré comme une adresse valide', () {
      final form = NouveauImmeubleForm()
        ..adresse = '   '
        ..ville = 'Cotonou';

      expect(form.isStep2Valid(), isFalse);
    });
  });
}
