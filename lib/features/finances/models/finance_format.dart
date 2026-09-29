/// Formats d'affichage partagés par les écrans Finances.
///
/// Même format de montant que `formatMontant` (`immeuble_detail_screen.dart`)
/// et les copies privées du tableau de bord et des locataires : copie ici
/// plutôt qu'un import d'écran d'une autre fonctionnalité.
library;

/// « 1 560 000 F ».
String formatMontant(double value) {
  final rounded = value.round();
  final isNegative = rounded < 0;
  final digits = rounded.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(' ');
    buffer.write(digits[i]);
  }
  return '${isNegative ? '-' : ''}$buffer F';
}

/// « +185 000 F » / « -45 000 F » (zéro sans signe).
String formatMontantSigne(double value) {
  if (value.round() == 0) return formatMontant(0);
  return value > 0 ? '+${formatMontant(value)}' : formatMontant(value);
}

/// « 15/09/2026 ».
String formatDateLongue(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/'
    '${date.month.toString().padLeft(2, '0')}/${date.year}';

/// « 15/09 ».
String formatDateCourte(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/'
    '${date.month.toString().padLeft(2, '0')}';

const _moisNoms = [
  'Janvier',
  'Février',
  'Mars',
  'Avril',
  'Mai',
  'Juin',
  'Juillet',
  'Août',
  'Septembre',
  'Octobre',
  'Novembre',
  'Décembre',
];

/// « Septembre 2026 ».
String formatMois(DateTime mois) => '${_moisNoms[mois.month - 1]} ${mois.year}';

/// Libellé d'un mode de paiement (valeurs envoyées par le web et le
/// backend : `especes`, `mobile_money`, `virement`, `cheque`, `carte`) ;
/// texte libre sinon, affiché tel quel.
String libelleModePaiement(String? mode) {
  switch (mode) {
    case null:
    case '':
      return '—';
    case 'especes':
      return 'Espèces';
    case 'mobile_money':
      return 'Mobile Money';
    case 'virement':
      return 'Virement bancaire';
    case 'cheque':
      return 'Chèque';
    case 'carte':
      return 'Carte bancaire';
  }
  return mode;
}

/// Libellé d'un type de paiement (`loyer` par défaut, texte libre sinon :
/// le web envoie aussi `Caution`, `Charges`…).
String libelleTypePaiement(String? type) {
  final t = type?.trim() ?? '';
  if (t.isEmpty || t == 'loyer') return 'Loyer';
  return t[0].toUpperCase() + t.substring(1);
}

/// Libellé du statut d'un paiement (`valide`, `en_attente`, `annule`).
String libelleStatutPaiement(String statut) {
  switch (statut) {
    case 'valide':
      return 'Validé';
    case 'en_attente':
      return 'En attente';
    case 'annule':
      return 'Annulé';
  }
  return statut;
}
