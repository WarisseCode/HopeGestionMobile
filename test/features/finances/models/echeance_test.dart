import 'package:flutter_test/flutter_test.dart';
import 'package:hope_gestion_mobile/features/finances/models/echeance.dart';

/// Aujourd'hui fixe pour les tests d'échéance : 2026-09-28.
final _aujourdhui = DateTime(2026, 9, 28, 14);
DateTime _dans(int jours) =>
    DateTime(2026, 9, 28).add(Duration(days: jours));

Echeance _echeance({
  double total = 185000,
  double montantPaye = 0,
  String? status,
  String? statut,
  DateTime? dateEcheance,
}) => Echeance(
  id: 12,
  total: total,
  montantPaye: montantPaye,
  status: status,
  statut: statut,
  dateEcheance: dateEcheance,
);

void main() {
  group('Echeance.fromJson', () {
    test('parse une ligne réelle de payment_schedules', () {
      final e = Echeance.fromJson({
        'id': 12,
        'lease_id': 8,
        'total_amount': '185000.00',
        'amount_paid': '50000.00',
        'due_date': '2026-09-05T12:00:00.000Z',
        'status': 'partial',
        'statut': 'partiel',
        'numero_echeance': null,
        'description': 'Loyer 9/2026',
      });

      expect(e.id, 12);
      expect(e.leaseId, 8);
      expect(e.total, 185000);
      expect(e.montantPaye, 50000);
      expect(e.dateEcheance, DateTime(2026, 9, 5));
      expect(e.description, 'Loyer 9/2026');
    });

    test('amount_paid absent → 0', () {
      final e = Echeance.fromJson({'id': 1, 'total_amount': '185000.00'});
      expect(e.montantPaye, 0);
    });

    test('id ou total_amount manquant → FormatException', () {
      expect(() => Echeance.fromJson({'total_amount': '185000'}), throwsFormatException);
      expect(() => Echeance.fromJson({'id': 1}), throwsFormatException);
    });
  });

  group('resteDu', () {
    test('total moins déjà versé', () {
      expect(_echeance(total: 185000, montantPaye: 50000).resteDu, 135000);
    });

    test('jamais négatif (trop-perçu)', () {
      expect(_echeance(total: 185000, montantPaye: 200000).resteDu, 0);
    });

    test('soldée exactement : reste 0', () {
      expect(_echeance(total: 185000, montantPaye: 185000).resteDu, 0);
    });
  });

  group('état (quatre valeurs)', () {
    test('à payer : rien versé, non échue', () {
      final e = _echeance(dateEcheance: _dans(5));
      expect(e.etat(maintenant: _aujourdhui), EtatEcheance.aPayer);
      expect(e.estSoldee, isFalse);
      expect(e.estAcompte, isFalse);
    });

    test('acompte : status = partial', () {
      final e = _echeance(status: 'partial', montantPaye: 50000, dateEcheance: _dans(5));
      expect(e.etat(maintenant: _aujourdhui), EtatEcheance.acompte);
    });

    test('acompte : statut = partiel (POST /api/paiements)', () {
      final e = _echeance(statut: 'partiel', montantPaye: 50000, dateEcheance: _dans(5));
      expect(e.etat(maintenant: _aujourdhui), EtatEcheance.acompte);
    });

    test('acompte : amount_paid > 0 seul (aucune des deux colonnes de statut)', () {
      final e = _echeance(montantPaye: 20000, dateEcheance: _dans(5));
      expect(e.etat(maintenant: _aujourdhui), EtatEcheance.acompte);
    });

    test('en retard : non soldée, date d\'échéance passée', () {
      final e = _echeance(dateEcheance: _dans(-1));
      expect(e.etat(maintenant: _aujourdhui), EtatEcheance.enRetard);
    });

    test('due aujourd\'hui : pas encore en retard', () {
      final e = _echeance(dateEcheance: _dans(0));
      expect(e.etat(maintenant: _aujourdhui), EtatEcheance.aPayer);
      expect(e.estEnRetard(maintenant: _aujourdhui), isFalse);
    });

    test('en retard prime sur acompte pour etat(), mais estAcompte reste vrai', () {
      final e = _echeance(montantPaye: 50000, dateEcheance: _dans(-3));
      // Badge principal : en retard (priorité documentée), pas acompte.
      expect(e.etat(maintenant: _aujourdhui), EtatEcheance.enRetard);
      // Le montant déjà versé reste lisible indépendamment de l'état retenu :
      // `estAcompte` (utilisé pour la ligne « Versé X · Reste Y ») n'est pas
      // masqué par la priorité de `etat()`.
      expect(e.estAcompte, isTrue);
      expect(e.montantPaye, 50000);
    });

    test('payée : status = paid, même en retard', () {
      final e = _echeance(status: 'paid', montantPaye: 185000, dateEcheance: _dans(-10));
      expect(e.etat(maintenant: _aujourdhui), EtatEcheance.payee);
    });

    test('payée : statut = paye seul', () {
      final e = _echeance(statut: 'paye', dateEcheance: _dans(-10));
      expect(e.etat(maintenant: _aujourdhui), EtatEcheance.payee);
    });

    test('payée : amount_paid >= total_amount seul', () {
      final e = _echeance(montantPaye: 185000, dateEcheance: _dans(-10));
      expect(e.etat(maintenant: _aujourdhui), EtatEcheance.payee);
    });

    test('sans date d\'échéance : jamais en retard', () {
      final e = _echeance();
      expect(e.etat(maintenant: _aujourdhui), EtatEcheance.aPayer);
    });
  });
}
