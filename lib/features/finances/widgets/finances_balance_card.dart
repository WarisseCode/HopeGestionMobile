import 'package:flutter/material.dart';

import '../../../core/design_system.dart';
import '../models/transaction.dart';

/// Carte sombre présentant le solde disponible et la synthèse entrées/sorties
/// Conforme à la maquette 05-finances.png
class FinancesBalanceCard extends StatelessWidget {
  const FinancesBalanceCard({super.key, required this.metrics});

  final FinanceMetrics metrics;

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
          // Label uppercase
          Text(
            'SOLDE DISPONIBLE',
            style: AppTypography.labelUppercase(
              color: const Color(0xFF708C86),
              fontSize: 10.5,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),

          // Montant principal
          Text(
            metrics.availableBalance,
            style: AppTypography.kpiValue(color: Colors.white, fontSize: 32),
          ),
          const SizedBox(height: 20),

          // Entrées / Sorties
          Row(
            children: [
              // Entrées
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      metrics.totalIncome,
                      style: AppTypography.titleSection(
                        color: const Color(0xFF00C49F),
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Entrées',
                      style: AppTypography.kpiNote(
                        color: const Color(0xFF8BA8A2),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // Sorties
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      metrics.totalExpenses,
                      style: AppTypography.titleSection(
                        color: Colors.white,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Sorties',
                      style: AppTypography.kpiNote(
                        color: const Color(0xFF8BA8A2),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
