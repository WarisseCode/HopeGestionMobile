import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../core/design_system.dart';

/// Écran de confirmation de création d'un bien.
class BienSuccesScreen extends StatelessWidget {
  const BienSuccesScreen({super.key, required this.nomBien});

  final String nomBien;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Icône de succès
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppColors.positiveSoft,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    LucideIcons.circle_check,
                    size: 48,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'Bien créé avec succès !',
                style: AppTypography.titleScreen(),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              Text(
                'Le bien « $nomBien » a été enregistré dans votre portefeuille immobilier.',
                style: AppTypography.body(color: AppColors.mutedForeground),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: AppRadius.borderMd,
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.building,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        nomBien,
                        style: AppTypography.body(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.positiveSoft,
                        borderRadius: AppRadius.borderSm,
                      ),
                      child: Text(
                        'Actif',
                        style: AppTypography.kpiNote(
                          color: AppColors.primaryStrong,
                          fontSize: 11,
                        ).copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Boutons d'action
              AppButton(
                label: 'Voir mes biens',
                icon: const Icon(
                  LucideIcons.arrow_right,
                  size: 16,
                  color: Colors.white,
                ),
                isFullWidth: true,
                onPressed: () {
                  // Fermer jusqu'à la racine
                  Navigator.of(context).pop(true);
                },
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.foreground,
                  side: BorderSide(color: AppColors.border),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.borderMd,
                  ),
                ),
                child: Text(
                  'Fermer',
                  style: AppTypography.button(color: AppColors.foreground),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
