import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../core/design_system.dart';
import '../../../core/i18n/app_strings.dart';
import '../../../core/i18n/locale_controller.dart';

/// Section « CRÉER » avec les 4 raccourcis de création rapide
class DashboardQuickActions extends StatelessWidget {
  final ValueChanged<String>? onActionTap;

  const DashboardQuickActions({super.key, this.onActionTap});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocaleController.instance,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête de la section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppStrings.t('CRÉER'),
                  style: AppTypography.labelUppercase(
                    fontSize: 11,
                    color: AppColors.mutedForeground,
                    letterSpacing: 0.8,
                  ),
                ),
                Text(
                  AppStrings.t('4 actions'),
                  style: AppTypography.kpiNote(
                    fontSize: 11,
                    color: AppColors.mutedForeground,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Grille horizontale de 4 boutons
            Row(
              children: [
                _ActionItem(
                  label: AppStrings.t('Bien'),
                  icon: LucideIcons.building,
                  onTap: () => onActionTap?.call('property'),
                ),
                const SizedBox(width: 8),
                _ActionItem(
                  label: AppStrings.t('Locataire'),
                  icon: LucideIcons.user_plus,
                  onTap: () => onActionTap?.call('tenant'),
                ),
                const SizedBox(width: 8),
                _ActionItem(
                  label: AppStrings.t('Facture'),
                  icon: LucideIcons.file_text,
                  onTap: () => onActionTap?.call('invoice'),
                ),
                const SizedBox(width: 8),
                _ActionItem(
                  label: AppStrings.t('Quittance'),
                  icon: LucideIcons.receipt,
                  onTap: () => onActionTap?.call('receipt'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _ActionItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionItem({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.secondary,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTypography.bodyMedium(fontSize: 12),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
