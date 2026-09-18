import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_typography.dart';

/// Dropdown stylé conforme au Design System HopeGestion.
class AppDropdown<T> extends StatelessWidget {
  const AppDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hintText = 'Sélectionner...',
    this.label,
    this.isRequired = false,
  });

  final T? value;
  final List<AppDropdownItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String hintText;
  final String? label;
  final bool isRequired;

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
              style: AppTypography.labelField(),
              children: [
                if (isRequired)
                  TextSpan(
                    text: ' *',
                    style: AppTypography.labelField(color: AppColors.negative),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
        ],
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.inputFill,
            borderRadius: AppRadius.borderMd,
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              icon: Icon(
                LucideIcons.chevron_down,
                size: 18,
                color: AppColors.mutedForeground,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              borderRadius: AppRadius.borderMd,
              style: AppTypography.body(),
              dropdownColor: AppColors.card,
              hint: Text(
                hintText,
                style: AppTypography.body(color: AppColors.mutedForeground),
              ),
              onChanged: onChanged,
              items: items
                  .map(
                    (item) => DropdownMenuItem<T>(
                      value: item.value,
                      child: Text(item.label, style: AppTypography.body()),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }
}

/// Entrée d'un [AppDropdown].
class AppDropdownItem<T> {
  const AppDropdownItem({required this.label, required this.value});
  final String label;
  final T value;
}
