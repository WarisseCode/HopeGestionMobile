import 'package:flutter_test/flutter_test.dart';
import 'package:hope_gestion_mobile/features/finances/models/depense.dart';
import 'package:hope_gestion_mobile/features/finances/models/mouvement.dart';
import 'package:hope_gestion_mobile/features/finances/models/paiement.dart';

Paiement _paiement(int id, DateTime date, {DateTime? createdAt}) => Paiement(
  id: id,
  montant: 185000,
  date: date,
  createdAt: createdAt,
  type: 'loyer',
  referenceBail: 'BAIL-00$id',
  locataireNom: 'Diop',
  locatairePrenoms: 'Yacine',
);

Depense _depense(int id, DateTime date, {DateTime? createdAt}) => Depense(
  id: id,
  categorie: 'Travaux / Entretien',
  montant: 45000,
  date: date,
  createdAt: createdAt,
  description: 'Réparation plomberie',
  immeubleNom: 'Résidence Palmiers',
  lotReference: 'A1',
);

String _cle(Mouvement m) => '${m.estEntree ? 'P' : 'D'}${m.id}';

void main() {
  group('Mouvement.fusionner', () {
    test('fusionne paiements et dépenses, triés par date décroissante', () {
      final mouvements = Mouvement.fusionner(
        [_paiement(1, DateTime(2026, 9, 3)), _paiement(2, DateTime(2026, 9, 20))],
        [_depense(7, DateTime(2026, 9, 10)), _depense(8, DateTime(2026, 9, 25))],
      );

      expect(mouvements.map(_cle), ['D8', 'P2', 'D7', 'P1']);
    });

    test('entrées positives, sorties négatives', () {
      final mouvements = Mouvement.fusionner(
        [_paiement(1, DateTime(2026, 9, 3))],
        [_depense(7, DateTime(2026, 9, 10))],
      );

      final depense = mouvements.firstWhere((m) => !m.estEntree);
      final paiement = mouvements.firstWhere((m) => m.estEntree);
      expect(paiement.montantSigne, 185000);
      expect(depense.montantSigne, -45000);
    });

    test('même jour : saisie la plus récente d\'abord, sans saisie en dernier',
        () {
      final jour = DateTime(2026, 9, 15);
      final mouvements = Mouvement.fusionner(
        [
          _paiement(1, jour, createdAt: DateTime(2026, 9, 15, 8)),
          _paiement(2, jour),
        ],
        [_depense(7, jour, createdAt: DateTime(2026, 9, 15, 17))],
      );

      expect(mouvements.map(_cle), ['D7', 'P1', 'P2']);
    });

    test('même jour sans saisie : paiements avant dépenses, puis id décroissant',
        () {
      final jour = DateTime(2026, 9, 15);
      final mouvements = Mouvement.fusionner(
        [_paiement(1, jour), _paiement(3, jour)],
        [_depense(9, jour)],
      );

      expect(mouvements.map(_cle), ['P3', 'P1', 'D9']);
    });

    test('listes vides → aucun mouvement', () {
      expect(Mouvement.fusionner(const [], const []), isEmpty);
    });
  });

  group('libellés', () {
    test('paiement : locataire, type et bail', () {
      final m = MouvementPaiement(_paiement(1, DateTime(2026, 9, 3)));

      expect(m.titre, 'Yacine Diop');
      expect(m.sousTitre, 'Loyer · BAIL-001');
    });

    test('paiement sans locataire ni bail', () {
      final m = MouvementPaiement(
        Paiement(id: 1, montant: 1, date: DateTime(2026, 9, 3), type: 'Caution'),
      );

      expect(m.titre, 'Paiement');
      expect(m.sousTitre, 'Caution');
    });

    test('dépense : description, catégorie, immeuble et lot', () {
      final m = MouvementDepense(_depense(7, DateTime(2026, 9, 10)));

      expect(m.titre, 'Réparation plomberie');
      expect(m.sousTitre, 'Travaux / Entretien · Résidence Palmiers · A1');
    });

    test('dépense sans description : la catégorie n\'est pas répétée', () {
      final m = MouvementDepense(
        Depense(
          id: 7,
          categorie: 'Taxes',
          montant: 1,
          date: DateTime(2026, 9, 10),
          description: '',
        ),
      );

      expect(m.titre, 'Taxes');
      expect(m.sousTitre, '');
    });
  });
}
