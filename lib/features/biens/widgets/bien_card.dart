import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../core/design_system.dart';
import '../models/bien.dart';

/// Carte d un bien immobilier dans la liste Biens.
class BienCard extends StatelessWidget {
  const BienCard({super.key, required this.bien, this.onTap, this.onMenu});

  final Bien bien;
  final VoidCallback? onTap;
  final VoidCallback? onMenu;

  @override
  Widget build(BuildContext context) {
    final isOccupe = bien.status == BienStatus.occupe;

    return AppCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(AppRadius.lg),
              bottomLeft: Radius.circular(AppRadius.lg),
            ),
            child: Container(
              width: 110,
              height: 100,
              color: AppColors.muted,
              child: bien.imageUrl != null
                  ? Image.network(
                      bien.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _placeholder(),
                    )
                  : _placeholder(),
            ),
          ),

          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge statut
                  isOccupe
                      ? const AppBadge.positive('OCCUPÉ', isUppercase: false)
                      : const AppBadge.neutral('VACANT', isUppercase: false),
                  const SizedBox(height: 6),

                  // Nom
                  Text(
                    bien.name,
                    style: AppTypography.titleSection(fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),

                  // Type
                  Text(
                    bien.type,
                    style: AppTypography.bodySmall(
                      color: AppColors.mutedForeground,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Prix
                  Text(
                    bien.price,
                    style: AppTypography.bodySmall(
                      color: AppColors.foreground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Menu
          IconButton(
            icon: Icon(
              LucideIcons.ellipsis_vertical,
              size: 18,
              color: AppColors.mutedForeground,
            ),
            onPressed: onMenu,
            padding: const EdgeInsets.fromLTRB(0, 8, 8, 0),
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.muted,
      child: Icon(
        LucideIcons.building,
        size: 36,
        color: AppColors.mutedForeground,
      ),
    );
  }
}
