import 'package:flutter_test/flutter_test.dart';
import 'package:hope_gestion_mobile/features/documents/models/document.dart';
import 'package:hope_gestion_mobile/features/documents/models/element_document.dart';

Document _doc(int id, {DateTime? le, String nom = 'Fichier', String? url}) =>
    Document(
      id: id,
      nom: nom,
      categorie: CategorieDocument.facture,
      createdAt: le,
      url: url,
    );

QuittanceManuelle _quittance(int id, {DateTime? emise, DateTime? saisie}) =>
    QuittanceManuelle(
      id: id,
      numero: 'QUI-MAN-2026-${id.toString().padLeft(4, '0')}',
      locataireNom: 'Yacine Diop',
      periode: 'Septembre 2026',
      montant: 185000,
      dateEmission: emise,
      createdAt: saisie,
    );

void main() {
  group('ElementDocument.fusionner', () {
    test('date décroissante, toutes sources confondues', () {
      final liste = ElementDocument.fusionner(
        [_doc(1, le: DateTime(2026, 9, 12)), _doc(2, le: DateTime(2026, 9, 1))],
        [_quittance(10, emise: DateTime(2026, 9, 5))],
      );

      expect(liste.map((e) => e.cle), ['doc-1', 'qm-10', 'doc-2']);
    });

    test('sans date en dernier', () {
      final liste = ElementDocument.fusionner(
        [_doc(1), _doc(2, le: DateTime(2026, 9, 1))],
        [_quittance(10)],
      );

      expect(liste.first.cle, 'doc-2');
      expect(liste.skip(1).map((e) => e.date), everyElement(isNull));
    });

    test('même date : fichiers avant quittances, puis id décroissant', () {
      final jour = DateTime(2026, 9, 10);
      final liste = ElementDocument.fusionner(
        [_doc(1, le: jour), _doc(3, le: jour)],
        [_quittance(2, emise: jour)],
      );

      expect(liste.map((e) => e.cle), ['doc-3', 'doc-1', 'qm-2']);
    });

    test('quittance sans date d’émission : repli sur created_at', () {
      final liste = ElementDocument.fusionner(
        [_doc(1, le: DateTime(2026, 9, 1))],
        [_quittance(10, saisie: DateTime(2026, 9, 20))],
      );

      expect(liste.first.cle, 'qm-10');
    });

    test('listes vides → liste vide', () {
      expect(ElementDocument.fusionner(const [], const []), isEmpty);
    });
  });

  group('libellés et recherche', () {
    test('fichier : titre = nom, sous-titre catégorie · date · taille', () {
      final e = ElementFichier(
        Document(
          id: 1,
          nom: 'Bail_42.pdf',
          categorie: CategorieDocument.bail,
          createdAt: DateTime(2026, 9, 12, 10),
          tailleOctets: 245760,
          url: '/uploads/x.pdf',
        ),
      );
      expect(e.titre, 'Bail_42.pdf');
      expect(e.sousTitre, 'Bail · 12/09/2026 · 240 Ko');
      expect(e.aUnFichier, isTrue);
    });

    test('fichier sans URL : pas de fichier à ouvrir', () {
      expect(ElementFichier(_doc(1)).aUnFichier, isFalse);
    });

    test('quittance manuelle : catégorie Quittances, jamais de fichier', () {
      final e = ElementQuittanceManuelle(_quittance(4));
      expect(e.titre, 'Quittance QUI-MAN-2026-0004');
      expect(e.sousTitre, 'Yacine Diop · Septembre 2026 · 185 000 F');
      expect(e.categorie, CategorieDocument.quittance);
      expect(e.aUnFichier, isFalse);
    });

    test('quittance sans numéro : titre générique', () {
      final e = ElementQuittanceManuelle(const QuittanceManuelle(id: 1));
      expect(e.titre, 'Quittance manuelle');
      expect(e.sousTitre, isEmpty);
    });

    test('recherche insensible à la casse, sur titre et sous-titre', () {
      final fichier = ElementFichier(_doc(1, nom: 'Facture Plombier.pdf'));
      final quittance = ElementQuittanceManuelle(_quittance(4));

      expect(fichier.correspondA('plombier'), isTrue);
      expect(fichier.correspondA('  PLOMB '), isTrue);
      expect(fichier.correspondA('diop'), isFalse);
      expect(quittance.correspondA('diop'), isTrue);
      expect(quittance.correspondA(''), isTrue);
    });
  });
}
