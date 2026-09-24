import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../core/config/app_config.dart';
import '../../../core/design_system.dart';
import '../models/immeuble.dart';

/// Carte d'un immeuble dans la liste Biens — taux d'occupation déjà calculé
/// côté serveur (`nbLots`/`lotsOccupes`/`etatOccupation`, voir
/// `bienRoutes.ts`), pas de champ prix unique puisqu'un immeuble peut
/// contenir plusieurs lots à des loyers différents (contrairement à
/// l'ancien `Bien` mocké qui n'en affichait qu'un).
class ImmeubleCard extends StatelessWidget {
  const ImmeubleCard({super.key, required this.immeuble, this.onTap});

  final Immeuble immeuble;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final badge = switch (immeuble.etatOccupation) {
      'Complet' => const AppBadge.positive('COMPLET', isUppercase: false),
      'En location' => const AppBadge.positive(
          'EN LOCATION',
          isUppercase: false,
        ),
      'Disponible' => const AppBadge.neutral(
          'DISPONIBLE',
          isUppercase: false,
        ),
      _ => const AppBadge.neutral('VIDE', isUppercase: false),
    };

    return AppCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(AppRadius.lg),
              bottomLeft: Radius.circular(AppRadius.lg),
            ),
            child: Container(
              width: 110,
              height: 100,
              color: AppColors.muted,
              child: immeuble.mainPhoto != null
                  ? Image.network(
                      AppConfig.resolveFileUrl(immeuble.mainPhoto!),
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _placeholder(),
                    )
                  : _placeholder(),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  badge,
                  const SizedBox(height: 6),
                  Text(
                    immeuble.nom,
                    style: AppTypography.titleSection(fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      immeuble.type,
                      immeuble.ville,
                    ].where((s) => s != null && s.isNotEmpty).join(' · '),
                    style: AppTypography.bodySmall(
                      color: AppColors.mutedForeground,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${immeuble.lotsOccupes}/${immeuble.nbLots} lot(s) occupé(s)',
                    style: AppTypography.bodySmall(
                      color: AppColors.foreground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.muted,
      child: Icon(
        LucideIcons.building,
        size: 36,
        color: AppColors.mutedForeground,
      ),
    );
  }
}
