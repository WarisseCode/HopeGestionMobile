import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_typography.dart';

/// Chip de sélection unique ou multiple dans les formulaires.
/// Utilisé pour : type de profil, mode de paiement, etc.
class AppToggleChip extends StatelessWidget {
  const AppToggleChip({
    super.key,
    required this.label,
    this.subtitle,
    this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final String? subtitle;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: subtitle != null ? 12 : 10,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.positiveSoft : AppColors.card,
          borderRadius: AppRadius.borderMd,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? AppColors.primaryStrong
                    : AppColors.mutedForeground,
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: AppTypography.bodySmall(
                      color: isSelected
                          ? AppColors.primaryStrong
                          : AppColors.foreground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: AppTypography.kpiNote(
                        color: isSelected
                            ? AppColors.primaryStrong
                            : AppColors.mutedForeground,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Option pour AppToggleChipGroup
class AppToggleChipOption<T> {
  const AppToggleChipOption({
    required this.label,
    required this.value,
    this.subtitle,
    this.icon,
  });

  final String label;
  final T value;
  final String? subtitle;
  final IconData? icon;
}

/// Groupe de chips à sélection unique
class AppToggleChipGroup<T> extends StatelessWidget {
  const AppToggleChipGroup({
    super.key,
    required this.options,
    required this.selectedValue,
    required this.onChanged,
  });

  final List<AppToggleChipOption<T>> options;
  final T selectedValue;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        return AppToggleChip(
          label: opt.label,
          subtitle: opt.subtitle,
          icon: opt.icon,
          isSelected: opt.value == selectedValue,
          onTap: () => onChanged(opt.value),
        );
      }).toList(),
    );
  }
}
