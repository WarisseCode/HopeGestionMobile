import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../core/design_system.dart';
import 'immeuble_detail_screen.dart';
import 'nouveau_lot_screen.dart';

/// Écran de confirmation après la création d'un immeuble, avec le choix
/// explicite demandé : ajouter un lot maintenant, ou terminer et en ajouter
/// plus tard depuis la fiche immeuble (approche validée : chaînage
/// immeuble → lots, cohérente avec `ImmeubleForm.tsx` côté web).
class ImmeubleCreeScreen extends StatelessWidget {
  const ImmeubleCreeScreen({
    super.key,
    required this.immeubleId,
    required this.nomImmeuble,
  });

  final int immeubleId;
  final String nomImmeuble;

  void _goToDetail(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ImmeubleDetailScreen(immeubleId: immeubleId),
      ),
    );
  }

  Future<void> _addLotNow(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NouveauLotScreen(
          buildingId: immeubleId,
          immeubleNom: nomImmeuble,
        ),
      ),
    );
    if (!context.mounted) return;
    _goToDetail(context);
  }

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
                'Immeuble créé avec succès !',
                style: AppTypography.titleScreen(),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              Text(
                'L\'immeuble « $nomImmeuble » a été enregistré. '
                'Voulez-vous y ajouter un lot maintenant ?',
                style: AppTypography.body(color: AppColors.mutedForeground),
                textAlign: TextAlign.center,
              ),

              const Spacer(),

              AppButton.primary(
                label: 'Ajouter un lot maintenant',
                icon: Icon(
                  LucideIcons.plus,
                  size: 16,
                  color: AppColors.primaryForeground,
                ),
                onPressed: () => _addLotNow(context),
              ),
              const SizedBox(height: 12),
              AppButton.secondary(
                label: 'Terminer, j\'ajouterai des lots plus tard',
                onPressed: () => _goToDetail(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
