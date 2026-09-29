/// Règles de validation du formulaire de dépense, en fonctions pures
/// (testables sans widget, sans réseau) — même approche que
/// `validerMontantEncaissement`/`validerDateEncaissement`
/// (`encaisser_screen.dart`, T-044). Partagées par `DepenseScreen` (contrôle
/// au moment de la sélection/saisie) et `FinancesRepository.creerDepense`
/// (contrôle défensif avant l'envoi) — voir ce dernier pour le contexte de
/// [validerTailleJustificatif] : le serveur (`uploadMiddleware.ts`) rejette
/// un fichier trop volumineux, mais sans code dédié (500 générique, voir
/// journal), d'où ce contrôle miroir côté mobile.
library;

/// Miroir de la limite serveur (`uploadMiddleware.ts`, `fileSize: 10 * 1024
/// * 1024`).
const int tailleMaxJustificatifOctets = 10 * 1024 * 1024;

String? validerMontantDepense(double? montant) {
  if (montant == null || montant <= 0) {
    return 'Indiquez un montant supérieur à 0.';
  }
  return null;
}

/// [date] et [aujourdhui] comparées jour civil (l'heure est ignorée).
String? validerDateDepense(DateTime date, DateTime aujourdhui) {
  final jourDate = DateTime(date.year, date.month, date.day);
  final jourAujourdhui = DateTime(aujourdhui.year, aujourdhui.month, aujourdhui.day);
  if (jourDate.isAfter(jourAujourdhui)) {
    return 'La date ne peut pas être dans le futur.';
  }
  return null;
}

String? validerTailleJustificatif(int octets) {
  if (octets > tailleMaxJustificatifOctets) {
    return 'Le fichier dépasse la taille maximale autorisée (10 Mo).';
  }
  return null;
}
