import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../core/design_system.dart';
import '../models/transaction.dart';

/// Ligne représentant une opération financière dans la section Dernières Opérations
class TransactionItem extends StatelessWidget {
  const TransactionItem({super.key, required this.transaction, this.onTap});

  final FinanceTransaction transaction;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.isIncome;

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
                    transaction.title,
                    style: AppTypography.body(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    transaction.subtitle,
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

            // Montant à droite
            Text(
              transaction.formattedAmount,
              style: AppTypography.body(
                fontWeight: FontWeight.w700,
                fontSize: 14.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
