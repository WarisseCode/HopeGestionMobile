import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../core/design_system.dart';

/// Ligne de contact dans la liste Locataires / Contacts. Prend des champs
/// simples plutôt qu'un modèle : réutilisée aussi bien pour les locataires
/// (`Locataire`) que pour les propriétaires (`Owner`), sans coupler ce
/// widget à l'un ou l'autre.
class ContactRow extends StatelessWidget {
  const ContactRow({
    super.key,
    required this.initials,
    required this.name,
    required this.info,
    this.photoUrl,
    this.onTap,
  });

  final String initials;
  final String name;

  /// Sous-titre, ex. « Locataire · Apt. 12 »
  final String info;

  /// URL déjà résolue (voir `AppConfig.resolveFileUrl`) — `null`/vide
  /// affiche les initiales.
  final String? photoUrl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Avatar avec initiales
            _avatar(),
            const SizedBox(width: 14),

            // Nom + info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: AppTypography.titleSection(fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    info,
                    style: AppTypography.bodySmall(
                      color: AppColors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),

            // Chevron
            Icon(
              LucideIcons.chevron_right,
              size: 18,
              color: AppColors.mutedForeground,
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatar() {
    if (photoUrl == null || photoUrl!.isEmpty) {
      return AppAvatar(initials: initials, size: 44);
    }
    return ClipOval(
      child: Image.network(
        photoUrl!,
        width: 44,
        height: 44,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => AppAvatar(initials: initials, size: 44),
      ),
    );
  }
}
