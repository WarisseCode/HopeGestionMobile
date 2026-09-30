import '../../finances/models/finance_format.dart';
import 'document.dart';

/// Ligne de la liste Documents : un fichier de `GET /api/documents` ou une
/// quittance manuelle de `GET /api/quittances`. Aucune route ne fusionne
/// les deux côté serveur (journal T-046), la liste est composée ici — même
/// principe que `Mouvement` dans Finances.
///
/// **Hors périmètre, volontairement** : les quittances de paiement
/// (`payments.quittance_url`, générées par `ReceiptService`) ne sont pas
/// listées ici, pour ne pas doublonner Finances ; elles restent accessibles
/// depuis la fiche d'un paiement (`TransactionDetailScreen`).
sealed class ElementDocument {
  const ElementDocument();

  /// Identifiant unique dans la liste fusionnée (les deux tables ont leurs
  /// propres séquences d'`id`).
  String get cle;

  int get id;
  String get titre;
  String get sousTitre;
  CategorieDocument get categorie;

  /// Date affichée et critère de tri ; `null` si le serveur n'en donne pas.
  DateTime? get date;

  /// Vrai si un fichier serveur peut être ouvert.
  bool get aUnFichier;

  /// Documents et quittances manuelles fusionnés, triés par date
  /// décroissante (sans date en dernier), puis les fichiers avant les
  /// quittances manuelles, puis par identifiant décroissant — ordre total,
  /// donc stable d'un chargement à l'autre.
  static List<ElementDocument> fusionner(
    Iterable<Document> documents,
    Iterable<QuittanceManuelle> quittances,
  ) {
    final elements = <ElementDocument>[
      ...documents.map(ElementFichier.new),
      ...quittances.map(ElementQuittanceManuelle.new),
    ];
    elements.sort(_comparer);
    return elements;
  }

  static int _comparer(ElementDocument a, ElementDocument b) {
    final da = a.date;
    final db = b.date;
    if (da != null && db != null) {
      final parDate = db.compareTo(da);
      if (parDate != 0) return parDate;
    } else if (da != null || db != null) {
      return da != null ? -1 : 1;
    }
    final aFichier = a is ElementFichier;
    final bFichier = b is ElementFichier;
    if (aFichier != bFichier) return aFichier ? -1 : 1;
    return b.id.compareTo(a.id);
  }

  /// Recherche insensible à la casse sur le titre et le sous-titre.
  bool correspondA(String requete) {
    final q = requete.trim().toLowerCase();
    if (q.isEmpty) return true;
    return titre.toLowerCase().contains(q) ||
        sousTitre.toLowerCase().contains(q);
  }
}

class ElementFichier extends ElementDocument {
  const ElementFichier(this.document);

  final Document document;

  @override
  String get cle => 'doc-${document.id}';
  @override
  int get id => document.id;
  @override
  String get titre => document.nom;

  /// « Bail · 12/09/2026 · 240 Ko » (éléments absents omis).
  @override
  String get sousTitre => [
    document.categorie.libelle,
    if (date != null) formatDateLongue(date!),
    if (document.tailleOctets != null) formatTaille(document.tailleOctets!),
  ].join(' · ');

  @override
  CategorieDocument get categorie => document.categorie;
  @override
  DateTime? get date => document.createdAt;
  @override
  bool get aUnFichier => document.url != null;
}

class ElementQuittanceManuelle extends ElementDocument {
  const ElementQuittanceManuelle(this.quittance);

  final QuittanceManuelle quittance;

  @override
  String get cle => 'qm-${quittance.id}';
  @override
  int get id => quittance.id;

  /// « Quittance QUI-MAN-2026-0004 » ; « Quittance manuelle » sans numéro.
  @override
  String get titre => quittance.numero == null
      ? 'Quittance manuelle'
      : 'Quittance ${quittance.numero}';

  /// « Yacine Diop · Septembre 2026 · 185 000 F ».
  @override
  String get sousTitre => [
    quittance.locataireNom,
    quittance.periode,
    if (quittance.montant != null) formatMontant(quittance.montant!),
  ].whereType<String>().join(' · ');

  @override
  CategorieDocument get categorie => CategorieDocument.quittance;

  @override
  DateTime? get date => quittance.dateEmission ?? quittance.createdAt;

  @override
  bool get aUnFichier => false;
}

/// « 850 o », « 240 Ko », « 1,2 Mo » (base 1024, virgule décimale).
String formatTaille(int octets) {
  if (octets < 1024) return '$octets o';
  final ko = octets / 1024;
  if (ko < 1024) return '${ko.round()} Ko';
  final mo = ko / 1024;
  return '${mo.toStringAsFixed(1).replaceAll('.', ',')} Mo';
}
