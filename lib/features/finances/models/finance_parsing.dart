/// Helpers de parsing partagés par les modèles Finances.
///
/// Le backend (node-postgres) renvoie les colonnes `NUMERIC` en **chaînes**
/// (`"185000.00"`) et les colonnes `DATE` sérialisées en instant ISO 8601
/// (objet `Date` JS → `"2026-09-14T23:00:00.000Z"` si le serveur tourne en
/// UTC+1). D'où ces conversions défensives plutôt qu'un simple `as num`.
library;

double? asDoubleOrNull(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

int? asIntOrNull(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

/// Date calendaire (sans heure) d'une colonne `DATE`.
///
/// - `"2026-09-15"` : pris tel quel.
/// - Instant ISO (`"2026-09-14T23:00:00.000Z"`) : converti en heure **locale**
///   avant d'extraire le jour. Une `DATE` sérialisée à minuit heure serveur
///   retombe ainsi sur le bon jour pour un appareil au même fuseau (Bénin,
///   UTC+1), comme pour un serveur en UTC (00:00Z → 01:00 locale, même jour).
DateTime? asDateOrNull(dynamic value) {
  if (value is! String || value.isEmpty) return null;
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return null;
  final local = parsed.isUtc ? parsed.toLocal() : parsed;
  return DateTime(local.year, local.month, local.day);
}

/// Instant (avec heure), en heure locale — pour `created_at`.
DateTime? asDateTimeOrNull(dynamic value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value)?.toLocal();
}

/// `"2026-09-15"` — format attendu par les filtres `start_date`/`end_date`.
String formatDateIso(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';
