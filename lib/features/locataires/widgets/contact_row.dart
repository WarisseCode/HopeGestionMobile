import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../core/design_system.dart';

/// Ligne de contact dans la liste Locataires / Contacts. Prend des champs
/// simples plutôt qu'un `Contact` (mock) : réutilisée depuis la phase 4.3
/// aussi bien pour des locataires réels (`Locataire`) que pour les
/// propriétaires encore mockés (`Contact`), sans coupler ce widget à l'un
/// ou l'autre modèle.
class ContactRow extends StatelessWidget {
  const ContactRow({
    super.key,
    required this.initials,
    required this.name,
    required this.info,
    this.onTap,
  });

  final String initials;
  final String name;

  /// Sous-titre, ex. « Locataire · Apt. 12 »
  final String info;
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
            AppAvatar(initials: initials, size: 44),
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
}
