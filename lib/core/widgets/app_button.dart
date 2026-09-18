import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_typography.dart';

enum AppButtonVariant { primary, secondary, ghost, danger }

/// Bouton standard HopeGestion Mobile
/// Hauteur 48px par défaut, arrondi 12px, ombre d'action optionnelle
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final Widget? icon;
  final Widget? trailingIcon;
  final bool isLoading;
  final bool isFullWidth;
  final double height;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.trailingIcon,
    this.isLoading = false,
    this.isFullWidth = true,
    this.height = 48,
  });

  const AppButton.primary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.trailingIcon,
    this.isLoading = false,
    this.isFullWidth = true,
    this.height = 48,
  }) : variant = AppButtonVariant.primary;

  const AppButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.trailingIcon,
    this.isLoading = false,
    this.isFullWidth = true,
    this.height = 48,
  }) : variant = AppButtonVariant.secondary;

  const AppButton.ghost({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.trailingIcon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.height = 40,
  }) : variant = AppButtonVariant.ghost;

  const AppButton.danger({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.trailingIcon,
    this.isLoading = false,
    this.isFullWidth = true,
    this.height = 48,
  }) : variant = AppButtonVariant.danger;

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color foregroundColor;
    Border? border;
    List<BoxShadow>? shadows;

    switch (variant) {
      case AppButtonVariant.primary:
        backgroundColor = AppColors.primary;
        foregroundColor = AppColors.primaryForeground;
        border = null;
        shadows = onPressed != null ? AppShadows.action : null;
        break;
      case AppButtonVariant.secondary:
        backgroundColor = AppColors.card;
        foregroundColor = AppColors.cardForeground;
        border = Border.all(color: AppColors.border, width: 1);
        shadows = null;
        break;
      case AppButtonVariant.ghost:
        backgroundColor = Colors.transparent;
        foregroundColor = AppColors.primary;
        border = null;
        shadows = null;
        break;
      case AppButtonVariant.danger:
        backgroundColor = AppColors.error;
        foregroundColor = AppColors.primaryForeground;
        border = null;
        shadows = null;
        break;
    }

    final isEnabled = onPressed != null && !isLoading;
    if (!isEnabled && variant == AppButtonVariant.primary) {
      backgroundColor = AppColors.muted;
      foregroundColor = AppColors.mutedForeground;
      shadows = null;
    }

    Widget content = Row(
      mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
            ),
          ),
          const SizedBox(width: 10),
        ] else if (icon != null) ...[
          icon!,
          const SizedBox(width: 8),
        ],
        Text(label, style: AppTypography.button(color: foregroundColor)),
        if (!isLoading && trailingIcon != null) ...[
          const SizedBox(width: 8),
          trailingIcon!,
        ],
      ],
    );

    return Container(
      height: height,
      width: isFullWidth ? double.infinity : null,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppRadius.borderSm,
        border: border,
        boxShadow: shadows,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled ? onPressed : null,
          borderRadius: AppRadius.borderSm,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(child: content),
          ),
        ),
      ),
    );
  }
}
