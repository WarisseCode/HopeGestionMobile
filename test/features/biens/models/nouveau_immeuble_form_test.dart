import 'package:flutter_test/flutter_test.dart';
import 'package:hope_gestion_mobile/features/biens/models/nouveau_immeuble_form.dart';

void main() {
  group('NouveauImmeubleForm.isStep2Valid', () {
    test(
      'adresse vide ne bloque plus la progression si la ville est '
      'renseignée (correctif T-033 sur T-032 : la contrainte NOT NULL de '
      'buildings.adresse est satisfaite par une chaîne vide, envoyée telle '
      'quelle par BiensRepository.createImmeuble — comportement du web)',
      () {
        final form = NouveauImmeubleForm()
          ..adresse = ''
          ..ville = 'Cotonou';

        expect(form.isStep2Valid(), isTrue);
      },
    );

    test('ville vide bloque la progression même si l\'adresse est renseignée', () {
      final form = NouveauImmeubleForm()
        ..adresse = '123 Rue de la Paix'
        ..ville = '';

      expect(form.isStep2Valid(), isFalse);
    });

    test('ville vide bloque la progression même si l\'adresse est aussi vide', () {
      final form = NouveauImmeubleForm()
        ..adresse = ''
        ..ville = '';

      expect(form.isStep2Valid(), isFalse);
    });

    test('adresse et ville renseignées valident l\'étape', () {
      final form = NouveauImmeubleForm()
        ..adresse = '123 Rue de la Paix'
        ..ville = 'Cotonou';

      expect(form.isStep2Valid(), isTrue);
    });
  });
}
