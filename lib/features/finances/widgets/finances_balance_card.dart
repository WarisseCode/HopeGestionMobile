import 'package:flutter/material.dart';

import '../../../core/design_system.dart';
import '../models/finance_format.dart';
import '../models/finance_stats.dart';

/// Carte sombre de synthèse du mois (`GET /api/finances/stats`).
///
/// Libellés alignés sur les définitions serveur (voir [FinanceStats]) : le
/// montant principal est le **solde du mois** (encaissé − dépenses du mois),
/// pas un solde de trésorerie cumulé.
class FinancesBalanceCard extends StatelessWidget {
  const FinancesBalanceCard({super.key, required this.stats});

  final FinanceStats stats;

  // Carte volontairement sombre dans les deux modes : elle puise dans la
  // palette sombre du thème (surface `card`, textes et statuts lisibles sur
  // fond sombre) plutôt que dans les getters dynamiques `AppColors`.
  static final _surface = darkPalette.card;
  static final _labelColor = darkPalette.mutedForeground;
  static final _noteColor = darkPalette.mutedForeground;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: darkPalette.background.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SOLDE DU MOIS',
            style: AppTypography.labelUppercase(
              color: _labelColor,
              fontSize: 10.5,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              formatMontantSigne(stats.soldeNet),
              style: AppTypography.kpiValue(color: Colors.white, fontSize: 32),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Encaissé moins dépenses du mois',
            style: AppTypography.kpiNote(color: _noteColor, fontSize: 12),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _Chiffre(
                  valeur: formatMontant(stats.encaisse),
                  libelle: 'Encaissé',
                  couleur: darkPalette.positive,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Chiffre(
                  valeur: formatMontant(stats.depenses),
                  libelle: 'Dépenses',
                  couleur: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Chiffre(
                  valeur: formatMontant(stats.resteAEncaisser),
                  libelle: 'Reste à encaisser',
                  couleur: darkPalette.warning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chiffre extends StatelessWidget {
  const _Chiffre({
    required this.valeur,
    required this.libelle,
    required this.couleur,
  });

  final String valeur;
  final String libelle;
  final Color couleur;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            valeur,
            style: AppTypography.titleSection(color: couleur, fontSize: 16),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          libelle,
          maxLines: 2,
          style: AppTypography.kpiNote(
            color: FinancesBalanceCard._noteColor,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
