import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_typography.dart';

class AppBottomNavItem {
  final String label;
  final IconData icon;

  const AppBottomNavItem({required this.label, required this.icon});
}

/// Barre de navigation flottante à 5 onglets HopeGestion Mobile
/// Conforme à la maquette 01-dashboard.png
class AppBottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  static const List<AppBottomNavItem> defaultItems = [
    AppBottomNavItem(label: 'Accueil', icon: LucideIcons.house),
    AppBottomNavItem(label: 'Biens', icon: LucideIcons.building),
    AppBottomNavItem(label: 'Contacts', icon: LucideIcons.users),
    AppBottomNavItem(label: 'Finances', icon: LucideIcons.arrow_up_right),
    AppBottomNavItem(label: 'Docs', icon: LucideIcons.file_text),
  ];

  const AppBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.borderLg,
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: AppShadows.navBar,
      ),
      child: Row(
        children: List.generate(defaultItems.length, (index) {
          final item = defaultItems[index];
          final isActive = index == currentIndex;

          return Expanded(
            child: _NavBarItem(
              item: item,
              isActive: isActive,
              onTap: () => onTap(index),
            ),
          );
        }),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final AppBottomNavItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isActive) {
      return Center(
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.borderMd,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.positiveSoft,
              borderRadius: AppRadius.borderMd,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(item.icon, size: 19, color: AppColors.primaryStrong),
                const SizedBox(height: 2),
                Text(
                  item.label,
                  style: AppTypography.kpiNote(
                    color: AppColors.primaryStrong,
                    fontSize: 9.5,
                  ).copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.borderMd,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(item.icon, size: 19, color: AppColors.mutedForeground),
            const SizedBox(height: 2),
            Text(
              item.label,
              style: AppTypography.kpiNote(
                color: AppColors.mutedForeground,
                fontSize: 9.5,
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
