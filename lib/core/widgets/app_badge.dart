import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_typography.dart';

enum AppBadgeType { positive, warning, danger, neutral, info }

/// Badge / Pill de statut HopeGestion Mobile
/// Exemples : "Payé", "En attente", "Impayé", "OCCUPÉ", "VACANT"
class AppBadge extends StatelessWidget {
  final String label;
  final AppBadgeType type;
  final bool isUppercase;
  final Widget? leading;

  const AppBadge({
    super.key,
    required this.label,
    this.type = AppBadgeType.neutral,
    this.isUppercase = false,
    this.leading,
  });

  const AppBadge.positive(
    this.label, {
    super.key,
    this.isUppercase = false,
    this.leading,
  }) : type = AppBadgeType.positive;

  const AppBadge.warning(
    this.label, {
    super.key,
    this.isUppercase = false,
    this.leading,
  }) : type = AppBadgeType.warning;

  const AppBadge.danger(
    this.label, {
    super.key,
    this.isUppercase = false,
    this.leading,
  }) : type = AppBadgeType.danger;

  const AppBadge.neutral(
    this.label, {
    super.key,
    this.isUppercase = false,
    this.leading,
  }) : type = AppBadgeType.neutral;

  const AppBadge.info(
    this.label, {
    super.key,
    this.isUppercase = false,
    this.leading,
  }) : type = AppBadgeType.info;

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;

    switch (type) {
      case AppBadgeType.positive:
        backgroundColor = AppColors.positiveSoft;
        textColor = AppColors.positive;
        break;
      case AppBadgeType.warning:
        backgroundColor = AppColors.warningSoft;
        textColor = AppColors.warning;
        break;
      case AppBadgeType.danger:
        backgroundColor = AppColors.errorSoft;
        textColor = AppColors.error;
        break;
      case AppBadgeType.neutral:
        backgroundColor = AppColors.muted;
        textColor = AppColors.mutedForeground;
        break;
      case AppBadgeType.info:
        backgroundColor = AppColors.infoSoft;
        textColor = AppColors.info;
        break;
    }

    final displayText = isUppercase ? label.toUpperCase() : label;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppRadius.borderFull,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 4)],
          Text(displayText, style: AppTypography.badge(color: textColor)),
        ],
      ),
    );
  }
}
