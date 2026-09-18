import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_typography.dart';

/// Avatar pour contacts, profils et gestionnaires
/// Supporte les initiales sur fond menthe ou une image
class AppAvatar extends StatelessWidget {
  final String? initials;
  final String? imageUrl;
  final double size;
  final bool isCircle;

  const AppAvatar({
    super.key,
    this.initials,
    this.imageUrl,
    this.size = 40,
    this.isCircle = false,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = isCircle ? AppRadius.borderFull : AppRadius.borderMd;

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          image: DecorationImage(
            image: NetworkImage(imageUrl!),
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.positiveSoft,
        borderRadius: borderRadius,
      ),
      child: Center(
        child: Text(
          (initials ?? 'HG').toUpperCase(),
          style: AppTypography.kpiNote(
            color: AppColors.primaryStrong,
            fontSize: size * 0.35,
          ).copyWith(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
