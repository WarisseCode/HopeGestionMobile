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

  /// Largeur du bloc photo, partagée avec `ImmeubleCardSkeleton`.
  static const double imageWidth = 104;

  /// Hauteur minimale de la carte : le bloc photo s'étire toujours sur toute
  /// la hauteur réelle (voir `build`), ce minimum évite juste une vignette
  /// trop écrasée quand le texte est court.
  static const double minHeight = 112;

  /// Libellé d'occupation avec accord correct (« 0 lot occupé sur 2 »,
  /// « 2 lots occupés sur 3 »). En français, 0 et 1 restent au singulier.
  static String occupationLabel(int occupes, int total) {
    if (total <= 0) return 'Aucun lot déclaré';
    final pluriel = occupes > 1;
    return '$occupes lot${pluriel ? 's' : ''} occupé${pluriel ? 's' : ''} '
        'sur $total';
  }

  @override
  Widget build(BuildContext context) {
    final etat = EtatOccupationStyle.of(immeuble.etatOccupation);
    final ratio = immeuble.nbLots > 0
        ? (immeuble.lotsOccupes / immeuble.nbLots).clamp(0.0, 1.0)
        : 0.0;
    final sousTitre = [
      immeuble.type,
      immeuble.ville,
    ].where((s) => s != null && s.isNotEmpty).join(' · ');
    final owner = immeuble.ownerName?.trim();

    return AppCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      // Rayon intérieur = rayon de la carte moins sa bordure de 1 px, pour
      // que la photo épouse exactement le coin arrondi.
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md - 1),
        // Stack plutôt que Row : c'est la colonne de texte (non positionnée)
        // qui fixe la hauteur, et la photo (positionnée) la remplit en
        // entier — plus de bande vide sous une vignette de hauteur fixe.
        // Évite aussi `IntrinsicHeight`, dont la mesure d'une `Image`
        // dépend du ratio de la photo (une photo portrait étirerait la carte).
        child: Stack(
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: minHeight),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(imageWidth + 12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppBadge(
                      label: etat.label,
                      type: etat.badgeType,
                      isUppercase: true,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      immeuble.nom,
                      style: AppTypography.titleSection(fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (sousTitre.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        sousTitre,
                        style: AppTypography.bodySmall(
                          color: AppColors.mutedForeground,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (owner != null && owner.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            LucideIcons.user,
                            size: 12,
                            color: AppColors.mutedForeground,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              owner,
                              style: AppTypography.caption(
                                color: AppColors.mutedForeground,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: AppRadius.borderFull,
                      child: LinearProgressIndicator(
                        value: ratio,
                        minHeight: 4,
                        backgroundColor: AppColors.muted,
                        valueColor: AlwaysStoppedAnimation(etat.color),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      occupationLabel(immeuble.lotsOccupes, immeuble.nbLots),
                      style: AppTypography.bodySmall(
                        color: AppColors.foreground,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: imageWidth,
              child: immeuble.mainPhoto != null
                  ? Image.network(
                      AppConfig.resolveFileUrl(immeuble.mainPhoto!),
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _placeholder(),
                    )
                  : _placeholder(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return ColoredBox(
      color: AppColors.secondary,
      child: Center(
        child: Icon(
          LucideIcons.building,
          size: 24,
          color: AppColors.primary.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}

/// Correspondance `etatOccupation` (calculé serveur, voir `bienRoutes.ts`)
/// → libellé, type de badge et couleur de la barre d'occupation.
class EtatOccupationStyle {
  const EtatOccupationStyle._(this.label, this.badgeType);

  final String label;
  final AppBadgeType badgeType;

  /// Même teinte que le texte du badge, pour que barre et badge concordent.
  Color get color => switch (badgeType) {
    AppBadgeType.positive => AppColors.positive,
    AppBadgeType.info => AppColors.info,
    AppBadgeType.warning => AppColors.warning,
    AppBadgeType.danger => AppColors.error,
    AppBadgeType.neutral => AppColors.mutedForeground,
  };

  static EtatOccupationStyle of(String? etat) => switch (etat) {
    'Complet' => const EtatOccupationStyle._('Complet', AppBadgeType.positive),
    'En location' => const EtatOccupationStyle._(
      'En location',
      AppBadgeType.info,
    ),
    // Aucun lot occupé : vacance totale, à signaler (ambre) sans l'alarme
    // du rouge réservé aux erreurs/impayés.
    'Disponible' => const EtatOccupationStyle._(
      'Disponible',
      AppBadgeType.warning,
    ),
    _ => const EtatOccupationStyle._('Vide', AppBadgeType.neutral),
  };
}
