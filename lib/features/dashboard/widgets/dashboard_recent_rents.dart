import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../core/design_system.dart';
import '../../../core/i18n/app_strings.dart';
import '../../../core/i18n/locale_controller.dart';
import '../models/dashboard_data.dart';

/// Section « LOYERS RÉCENTS » avec liste des derniers encaissements
class DashboardRecentRents extends StatelessWidget {
  final List<RecentRentPayment> rents;
  final VoidCallback? onSeeAllTap;
  final ValueChanged<RecentRentPayment>? onRentTap;

  const DashboardRecentRents({
    super.key,
    required this.rents,
    this.onSeeAllTap,
    this.onRentTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocaleController.instance,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête de section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppStrings.t('LOYERS RÉCENTS'),
                  style: AppTypography.labelUppercase(
                    fontSize: 11,
                    color: AppColors.mutedForeground,
                    letterSpacing: 0.8,
                  ),
                ),
                InkWell(
                  onTap: onSeeAllTap,
                  borderRadius: AppRadius.borderSm,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    child: Text(
                      AppStrings.t('Tout voir'),
                      style: AppTypography.bodySmall(color: AppColors.primary)
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Carte contenant la liste avec séparateurs
            AppCard(
              padding: EdgeInsets.zero,
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: rents.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color: AppColors.border,
                ),
                itemBuilder: (context, index) {
                  final rent = rents[index];
                  return _RentItemRow(
                    rent: rent,
                    onTap: () => onRentTap?.call(rent),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RentItemRow extends StatelessWidget {
  final RecentRentPayment rent;
  final VoidCallback onTap;

  const _RentItemRow({required this.rent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.borderMd,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // Miniature du bien
            _buildThumbnail(),
            const SizedBox(width: 12),

            // Nom du bien + Locataire
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rent.property,
                    style: AppTypography.bodyMedium(
                      fontSize: 13.5,
                      color: AppColors.foreground,
                    ).copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    rent.tenant,
                    style: AppTypography.bodySmall(
                      fontSize: 12,
                      color: AppColors.mutedForeground,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Montant + Statut
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  rent.amount,
                  style: AppTypography.bodyMedium(
                    fontSize: 13.5,
                    color: AppColors.foreground,
                  ).copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                _buildStatusBadge(rent.status),
              ],
            ),
            const SizedBox(width: 8),

            // Flèche Chevron
            Icon(
              LucideIcons.chevron_right,
              size: 16,
              color: AppColors.mutedForeground,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    if (rent.imageUrl != null && rent.imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: AppRadius.borderSm,
        child: Image.network(
          rent.imageUrl!,
          width: 44,
          height: 44,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _buildFallbackThumbnail(),
        ),
      );
    }
    return _buildFallbackThumbnail();
  }

  Widget _buildFallbackThumbnail() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: AppRadius.borderSm,
      ),
      child: Icon(LucideIcons.building, color: AppColors.primary, size: 20),
    );
  }

  Widget _buildStatusBadge(String status) {
    final lower = status.toLowerCase();
    if (lower.contains('payé') || lower.contains('paye')) {
      return AppBadge.positive(AppStrings.t('Payé'));
    } else if (lower.contains('attente')) {
      return AppBadge.neutral(AppStrings.t('En attente'));
    } else if (lower.contains('impayé') || lower.contains('impaye')) {
      return AppBadge.warning(AppStrings.t('Impayé'));
    }
    return AppBadge(label: status);
  }
}
