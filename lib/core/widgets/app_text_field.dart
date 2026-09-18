import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_typography.dart';

/// Champ de texte standard HopeGestion Mobile
/// Hauteur 48px, fond doux #F5FBFA, bordure #D4E0DE, rayon 12px
class AppTextField extends StatelessWidget {
  final String? label;
  final bool isRequired;
  final String? hintText;
  final String? helperText;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  final int maxLines;
  final VoidCallback? onTap;
  final bool readOnly;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;

  const AppTextField({
    super.key,
    this.label,
    this.isRequired = false,
    this.hintText,
    this.helperText,
    this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.errorText,
    this.onChanged,
    this.enabled = true,
    this.maxLines = 1,
    this.onTap,
    this.readOnly = false,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text.rich(
            TextSpan(
              text: label!,
              style: AppTypography.bodyMedium(
                fontSize: 13,
                color: AppColors.foreground,
              ),
              children: [
                if (isRequired)
                  TextSpan(
                    text: ' *',
                    style: AppTypography.bodyMedium(
                      fontSize: 13,
                      color: AppColors.negative,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
        ],
        SizedBox(
          height: maxLines == 1 ? 48 : null,
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            enabled: enabled,
            maxLines: maxLines,
            onChanged: onChanged,
            onTap: onTap,
            readOnly: readOnly,
            textCapitalization: textCapitalization,
            inputFormatters: inputFormatters,
            style: AppTypography.body(),
            textAlignVertical: TextAlignVertical.center,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: AppTypography.bodySmall(
                color: AppColors.mutedForeground,
              ),
              prefixIcon: prefixIcon,
              suffixIcon: suffixIcon,
              errorText: errorText,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              filled: true,
              fillColor: enabled ? AppColors.inputFill : AppColors.muted,
              border: OutlineInputBorder(
                borderRadius: AppRadius.borderSm,
                borderSide: BorderSide(color: AppColors.inputBorder, width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadius.borderSm,
                borderSide: BorderSide(color: AppColors.inputBorder, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppRadius.borderSm,
                borderSide: BorderSide(color: AppColors.primary, width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: AppRadius.borderSm,
                borderSide: BorderSide(color: AppColors.error, width: 1),
              ),
            ),
          ),
        ),
        if (helperText != null && errorText == null) ...[
          const SizedBox(height: 4),
          Text(
            helperText!,
            style: AppTypography.kpiNote(
              color: AppColors.mutedForeground,
              fontSize: 11,
            ),
          ),
        ],
      ],
    );
  }
}
