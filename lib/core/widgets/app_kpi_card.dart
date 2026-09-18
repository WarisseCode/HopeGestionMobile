import 'package:flutter/material.dart';

import '../i18n/app_strings.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'app_card.dart';

/// Carte KPI pour le Dashboard (Encaiss., Dépenses, Impayés)
/// Conforme à la maquette 01-dashboard.png
class AppKpiCard extends StatelessWidget {
  final String label;
  final String value;
  final String note;
  final bool isPositiveNote;
  final VoidCallback? onTap;

  const AppKpiCard({
    super.key,
    required this.label,
    required this.value,
    required this.note,
    this.isPositiveNote = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppStrings.t(label).toUpperCase(),
              style: AppTypography.labelUppercase(
                fontSize: 9.5,
                color: AppColors.mutedForeground,
                letterSpacing: 0.8,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: AppTypography.kpiValue(
                fontSize: 18,
                color: AppColors.foreground,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              AppStrings.t(note),
              style: AppTypography.kpiNote(
                fontSize: 9.5,
                color: isPositiveNote
                    ? AppColors.positive
                    : AppColors.mutedForeground,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
