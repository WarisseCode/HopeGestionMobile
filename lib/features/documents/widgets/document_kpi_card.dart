import 'package:flutter/material.dart';

import '../../../core/design_system.dart';

/// Carte KPI pour les statistiques de documents (Quittances, Contrats, Factures)
class DocumentKpiCard extends StatelessWidget {
  const DocumentKpiCard({
    super.key,
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.positiveSoft : AppColors.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: AppShadows.soft,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.labelUppercase(
                  color: isSelected
                      ? AppColors.primaryStrong
                      : AppColors.mutedForeground,
                  fontSize: 10,
                  letterSpacing: 0.6,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                count.toString(),
                style: AppTypography.kpiValue(
                  color: isSelected
                      ? AppColors.primaryStrong
                      : AppColors.foreground,
                  fontSize: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
