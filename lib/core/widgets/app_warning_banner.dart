import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_typography.dart';

/// Bannière d'avertissement contextuelle (fond ambre doux, icône ⚠️) —
/// pendant "attention" de `AppInfoBanner`.
class AppWarningBanner extends StatelessWidget {
  const AppWarningBanner({super.key, required this.text});

  /// Message standard affiché en haut des écrans de saisie pas encore
  /// branchés au backend (voir journal, T-025) — un seul endroit à mettre
  /// à jour si le libellé change, ou à retirer quand un écran est câblé.
  const AppWarningBanner.mockData({super.key})
    : text =
          'Fonctionnalité en cours de finalisation : les données saisies '
          'ici ne sont pas encore enregistrées.';

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.warningSoft,
        borderRadius: AppRadius.borderMd,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.circle_alert, size: 16, color: AppColors.warning),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodySmall(color: AppColors.warning),
            ),
          ),
        ],
      ),
    );
  }
}
