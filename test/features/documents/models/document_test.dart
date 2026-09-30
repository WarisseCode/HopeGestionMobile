import 'package:flutter_test/flutter_test.dart';
import 'package:hope_gestion_mobile/features/documents/models/document.dart';
import 'package:hope_gestion_mobile/features/documents/models/element_document.dart';

/// Forme réelle d'une ligne de `GET /api/documents` (`SELECT *`) : `taille`
/// stockée en chaîne par le serveur, `type` = type MIME.
Map<String, dynamic> _documentJson({
  Object? id = 7,
  Object? categorie = 'baux',
}) => {
  'id': id,
  'user_id': 1,
  'nom': 'Bail_42.pdf',
  'type': 'application/pdf',
  'url': '/uploads/2026/09/Bail_42_3f9a.pdf',
  'taille': '245760',
  'categorie': categorie,
  'entity_type': 'lease',
  'entity_id': 42,
  'description': 'Contrat de bail généré automatiquement',
  'owner_id': 3,
  'created_at': '2026-09-12T10:00:00.000Z',
  'deleted_at': null,
  'deleted_by': null,
};

/// Forme réelle d'une ligne de `GET /api/quittances` (`manual_quittances`).
Map<String, dynamic> _quittanceJson() => {
  'id': 4,
  'owner_id': 3,
  'lease_id': 42,
  'numero': 'QUI-MAN-2026-0004',
  'locataire_name': 'Yacine Diop',
  'proprietaire_name': 'Mamadou Camara',
  'proprietaire_adresse': null,
  'proprietaire_tel': null,
  'bien': 'Résidence Palmiers · A12',
  'periode': 'Septembre 2026',
  'montant': '185000.00',
  'date_emission': '2026-09-10T12:00:00.000Z',
  'created_by': 1,
  'created_at': '2026-09-10T15:30:00.000Z',
};

void main() {
  group('CategorieDocument.depuisCode (tolérant)', () {
    test('valeurs écrites par le serveur et le web', () {
      expect(CategorieDocument.depuisCode('baux'), CategorieDocument.bail);
      expect(
        CategorieDocument.depuisCode('quittances'),
        CategorieDocument.quittance,
      );
      expect(CategorieDocument.depuisCode('facture'), CategorieDocument.facture);
      expect(
        CategorieDocument.depuisCode('identite'),
        CategorieDocument.identite,
      );
      expect(
        CategorieDocument.depuisCode('proprietaire'),
        CategorieDocument.proprietaire,
      );
      expect(CategorieDocument.depuisCode('generated'), CategorieDocument.genere);
      expect(CategorieDocument.depuisCode('autre'), CategorieDocument.autre);
    });

    test('casse et espaces ignorés, variantes singulier/pluriel', () {
      expect(CategorieDocument.depuisCode('  BAUX '), CategorieDocument.bail);
      expect(CategorieDocument.depuisCode('Bail'), CategorieDocument.bail);
      expect(
        CategorieDocument.depuisCode('Quittance'),
        CategorieDocument.quittance,
      );
    });

    test('valeur inconnue, vide ou absente → Autre, jamais d’exception', () {
      expect(
        CategorieDocument.depuisCode('contrat_signe'),
        CategorieDocument.autre,
      );
      expect(CategorieDocument.depuisCode(''), CategorieDocument.autre);
      expect(CategorieDocument.depuisCode(null), CategorieDocument.autre);
    });
  });

  group('Document.tryFromJson', () {
    test('forme réelle : taille en chaîne, MIME, entité, date', () {
      final d = Document.tryFromJson(_documentJson())!;

      expect(d.id, 7);
      expect(d.nom, 'Bail_42.pdf');
      expect(d.categorie, CategorieDocument.bail);
      expect(d.typeMime, 'application/pdf');
      expect(d.url, '/uploads/2026/09/Bail_42_3f9a.pdf');
      expect(d.tailleOctets, 245760);
      expect(d.entiteLiee, 'Bail n° 42');
      expect(d.createdAt, DateTime.utc(2026, 9, 12, 10).toLocal());
    });

    test('catégorie inconnue : Autre, valeur brute conservée', () {
      final d = Document.tryFromJson(_documentJson(categorie: 'contrat_signe'))!;

      expect(d.categorie, CategorieDocument.autre);
      expect(d.categorieBrute, 'contrat_signe');
    });

    test('catégorie non textuelle (nombre) : Autre, sans exception', () {
      final d = Document.tryFromJson(_documentJson(categorie: 12))!;
      expect(d.categorie, CategorieDocument.autre);
      expect(d.categorieBrute, isNull);
    });

    test('id en chaîne accepté ; id absent → ligne ignorée (null)', () {
      expect(Document.tryFromJson(_documentJson(id: '7'))!.id, 7);
      expect(Document.tryFromJson(_documentJson(id: null)), isNull);
      expect(Document.tryFromJson(_documentJson(id: 'abc')), isNull);
    });

    test('champs manquants : valeurs nulles, nom de repli', () {
      final d = Document.tryFromJson({'id': 9})!;

      expect(d.nom, 'Document n° 9');
      expect(d.categorie, CategorieDocument.autre);
      expect(d.url, isNull);
      expect(d.tailleOctets, isNull);
      expect(d.typeMime, isNull);
      expect(d.entiteLiee, isNull);
      expect(d.createdAt, isNull);
    });

    test('nom vide : repli sur la description', () {
      final d = Document.tryFromJson({
        'id': 9,
        'nom': '   ',
        'description': 'Pièce d’identité',
      })!;
      expect(d.nom, 'Pièce d’identité');
    });

    test('taille numérique (colonne entière) acceptée aussi', () {
      final d = Document.tryFromJson({'id': 9, 'taille': 2048})!;
      expect(d.tailleOctets, 2048);
    });

    test('entité : types connus traduits, inconnus affichés tels quels', () {
      Document doc(String type, [int? id]) => Document.tryFromJson({
        'id': 1,
        'entity_type': type,
        'entity_id': id,
      })!;
      expect(doc('owner', 3).entiteLiee, 'Propriétaire n° 3');
      expect(doc('lot', 5).entiteLiee, 'Lot n° 5');
      expect(doc('building', 2).entiteLiee, 'Immeuble n° 2');
      expect(doc('tenant').entiteLiee, 'Locataire');
      expect(doc('mandat', 8).entiteLiee, 'mandat n° 8');
    });
  });

  group('QuittanceManuelle.tryFromJson', () {
    test('forme réelle : montant en chaîne, date d’émission calendaire', () {
      final q = QuittanceManuelle.tryFromJson(_quittanceJson())!;

      expect(q.id, 4);
      expect(q.numero, 'QUI-MAN-2026-0004');
      expect(q.locataireNom, 'Yacine Diop');
      expect(q.proprietaireNom, 'Mamadou Camara');
      expect(q.bien, 'Résidence Palmiers · A12');
      expect(q.periode, 'Septembre 2026');
      expect(q.montant, 185000);
      expect(q.dateEmission, DateTime(2026, 9, 10));
    });

    test('champs manquants tolérés ; id absent → null', () {
      final q = QuittanceManuelle.tryFromJson({'id': 1, 'montant': 'n/a'})!;
      expect(q.numero, isNull);
      expect(q.montant, isNull);
      expect(q.dateEmission, isNull);
      expect(QuittanceManuelle.tryFromJson({'numero': 'X'}), isNull);
    });
  });

  group('formatTaille', () {
    test('octets, Ko, Mo (base 1024, virgule)', () {
      expect(formatTaille(850), '850 o');
      expect(formatTaille(245760), '240 Ko');
      expect(formatTaille(1258291), '1,2 Mo');
    });
  });
}
