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

  static const _labelColor = Color(0xFF708C86);
  static const _noteColor = Color(0xFF8BA8A2);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1F1C), // Fond sombre verdâtre feutré
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0E1F1C).withValues(alpha: 0.25),
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
                  couleur: const Color(0xFF00C49F),
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
                  couleur: const Color(0xFFF5B754),
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
