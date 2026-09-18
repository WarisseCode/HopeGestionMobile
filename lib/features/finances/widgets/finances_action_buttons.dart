import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../core/design_system.dart';

/// Deux boutons d'action rapide sous la carte de solde : « Encaisser » et « Dépense »
class FinancesActionButtons extends StatelessWidget {
  const FinancesActionButtons({
    super.key,
    required this.onEncaisser,
    required this.onDepense,
  });

  final VoidCallback onEncaisser;
  final VoidCallback onDepense;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Bouton Encaisser (vert plein)
        Expanded(
          child: InkWell(
            onTap: onEncaisser,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.28),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.8),
                        ),
                        child: const Center(
                          child: Text(
                            r'$',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Encaisser',
                        style: AppTypography.button(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Bouton Dépense (contour blanc élégant)
        Expanded(
          child: InkWell(
            onTap: onDepense,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border, width: 1.2),
                boxShadow: AppShadows.soft,
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.receipt,
                        size: 18,
                        color: AppColors.foreground,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Dépense',
                        style: AppTypography.button(
                          color: AppColors.foreground,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
