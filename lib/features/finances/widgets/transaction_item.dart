import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../core/design_system.dart';
import '../models/finance_format.dart';
import '../models/mouvement.dart';

/// Ligne d'un mouvement du mois : entrée (paiement, montant positif) ou
/// sortie (dépense, montant négatif).
class TransactionItem extends StatelessWidget {
  const TransactionItem({super.key, required this.mouvement, this.onTap});

  final Mouvement mouvement;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isIncome = mouvement.estEntree;
    // Un paiement annulé ou en attente reste listé, mais ne compte pas dans
    // l'encaissé du mois (`GET /finances/stats` : statut `valide` seulement).
    final m = mouvement;
    final statutNonValide = m is MouvementPaiement && !m.paiement.estValide
        ? libelleStatutPaiement(m.paiement.statut)
        : null;
    final sousTitre = [
      formatDateCourte(mouvement.date),
      if (mouvement.sousTitre.isNotEmpty) mouvement.sousTitre,
      ?statutNonValide,
    ].join(' · ');

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            // Badge circulaire avec flèche entrante ou sortante
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isIncome
                    ? AppColors.positiveSoft
                    : AppColors.warningSoft,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  isIncome
                      ? LucideIcons.arrow_down_left
                      : LucideIcons.arrow_up_right,
                  size: 20,
                  color: isIncome ? AppColors.primary : AppColors.warning,
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Titre & Sous-titre
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mouvement.titre,
                    style: AppTypography.body(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sousTitre,
                    style: AppTypography.bodySmall(
                      color: AppColors.mutedForeground,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Montant à droite
            Text(
              formatMontantSigne(mouvement.montantSigne),
              style: AppTypography.body(
                fontWeight: FontWeight.w700,
                fontSize: 14.5,
                color: statutNonValide != null
                    ? AppColors.mutedForeground
                    : isIncome
                    ? AppColors.positive
                    : AppColors.foreground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
