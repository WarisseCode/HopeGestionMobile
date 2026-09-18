import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';

/// Floating Action Button circulaire de 56px avec ombre portée teal
/// Utilisé pour l'Action Rapide sur le Dashboard et les listes
class AppFab extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final double size;

  const AppFab({
    super.key,
    required this.onPressed,
    this.icon = LucideIcons.plus,
    this.size = 56,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
        boxShadow: AppShadows.action,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Center(
            child: Icon(icon, color: AppColors.primaryForeground, size: 26),
          ),
        ),
      ),
    );
  }
}
