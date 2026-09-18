import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../core/design_system.dart';
import '../../../core/i18n/app_strings.dart';
import '../../../core/i18n/locale_controller.dart';

/// En-tête du Dashboard conforme à la maquette 01-dashboard.png
class DashboardHeader extends StatelessWidget {
  final String dateFormatted;
  final String userName;
  final String? avatarUrl;
  final VoidCallback? onNotificationsTap;
  final VoidCallback? onProfileTap;

  const DashboardHeader({
    super.key,
    required this.dateFormatted,
    required this.userName,
    this.avatarUrl,
    this.onNotificationsTap,
    this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocaleController.instance,
      builder: (context, _) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Textes Date + Salutation
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.t(dateFormatted).toUpperCase(),
                    style: AppTypography.labelUppercase(
                      fontSize: 11,
                      color: AppColors.mutedForeground,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppStrings.t('Bonjour, {name}', {'name': userName}),
                    style: AppTypography.titleScreen(fontSize: 22),
                  ),
                ],
              ),
            ),

            // Bouton Notifications avec point indicateur vert
            _HeaderCircleButton(
              icon: LucideIcons.bell,
              hasBadge: true,
              onTap: onNotificationsTap,
            ),
            const SizedBox(width: 10),

            // Bouton Profil (avatar réel de l'utilisateur)
            _HeaderAvatarButton(
              initials: _initialsFrom(userName),
              imageUrl: avatarUrl,
              onTap: onProfileTap,
            ),
          ],
        );
      },
    );
  }
}

/// Dérive des initiales (2 lettres max) à partir d'un nom complet,
/// pour éviter de dupliquer le nom de l'utilisateur en dur ailleurs.
String _initialsFrom(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '';
  final first = parts.first[0];
  final last = parts.length > 1 ? parts.last[0] : '';
  return ('$first$last').toUpperCase();
}

class _HeaderCircleButton extends StatelessWidget {
  final IconData icon;
  final bool hasBadge;
  final VoidCallback? onTap;

  const _HeaderCircleButton({
    required this.icon,
    this.hasBadge = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.card,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: AppShadows.soft,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              customBorder: const CircleBorder(),
              child: Center(
                child: Icon(icon, size: 19, color: AppColors.foreground),
              ),
            ),
          ),
          if (hasBadge)
            Positioned(
              top: 9,
              right: 11,
              child: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: AppColors.positive,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Bouton d'accès au profil : affiche l'avatar réel de l'utilisateur
/// (photo si renseignée, sinon initiales) au lieu d'une icône générique.
class _HeaderAvatarButton extends StatelessWidget {
  final String initials;
  final String? imageUrl;
  final VoidCallback? onTap;

  const _HeaderAvatarButton({
    required this.initials,
    this.imageUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.card,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: AppShadows.soft,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Center(
            child: AppAvatar(
              initials: initials,
              imageUrl: imageUrl,
              size: 38,
              isCircle: true,
            ),
          ),
        ),
      ),
    );
  }
}
