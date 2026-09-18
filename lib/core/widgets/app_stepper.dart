import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_typography.dart';

/// Barre d etapes réutilisable pour les formulaires multi-étapes HopeGestion.
/// Gère les icônes d étapes (actif, complété, futur) et les boutons de navigation.
class AppStepperHeader extends StatelessWidget {
  const AppStepperHeader({
    super.key,
    required this.steps,
    required this.currentStep,
    required this.title,
    required this.subtitle,
    required this.onClose,
  });

  final List<AppStepItem> steps;
  final int currentStep;
  final String title;
  final String subtitle;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Ligne titre + compteur + fermer
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 4),
            child: Row(
              children: [
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(LucideIcons.x, size: 20),
                  color: AppColors.foreground,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTypography.titleSection()),
                      Text(
                        subtitle,
                        style: AppTypography.bodySmall(
                          color: AppColors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${currentStep + 1} / ${steps.length}',
                  style: AppTypography.bodySmall(
                    color: AppColors.mutedForeground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Icônes d étapes
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: List.generate(steps.length, (i) {
                final state = i < currentStep
                    ? _StepState.done
                    : i == currentStep
                    ? _StepState.active
                    : _StepState.future;
                return Expanded(
                  child: _StepIcon(
                    item: steps[i],
                    state: state,
                    isLast: i == steps.length - 1,
                  ),
                );
              }),
            ),
          ),

          // Barre de progression
          LinearProgressIndicator(
            value: (currentStep + 1) / steps.length,
            backgroundColor: AppColors.muted,
            color: AppColors.primary,
            minHeight: 3,
          ),
        ],
      ),
    );
  }
}

enum _StepState { active, done, future }

class _StepIcon extends StatelessWidget {
  const _StepIcon({
    required this.item,
    required this.state,
    required this.isLast,
  });

  final AppStepItem item;
  final _StepState state;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    final Widget icon;

    switch (state) {
      case _StepState.active:
        bg = AppColors.primary;
        fg = Colors.white;
        icon = Icon(item.icon, size: 16, color: fg);
        break;
      case _StepState.done:
        bg = AppColors.positiveSoft;
        fg = AppColors.primaryStrong;
        icon = Icon(LucideIcons.check, size: 14, color: fg);
        break;
      case _StepState.future:
        bg = AppColors.muted;
        fg = AppColors.mutedForeground;
        icon = Icon(item.icon, size: 16, color: fg);
        break;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          child: Center(child: icon),
        ),
        const SizedBox(height: 4),
        Text(
          item.label,
          style:
              AppTypography.kpiNote(
                color: state == _StepState.active
                    ? AppColors.primaryStrong
                    : AppColors.mutedForeground,
                fontSize: 9.5,
              ).copyWith(
                fontWeight: state == _StepState.active
                    ? FontWeight.w600
                    : FontWeight.w400,
              ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Barre de boutons bas pour les formulaires multi-étapes.
class AppStepperNavBar extends StatelessWidget {
  const AppStepperNavBar({
    super.key,
    required this.onBack,
    required this.onNext,
    this.onSkip,
    required this.backLabel,
    required this.nextLabel,
    this.isNextEnabled = true,
  });

  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback? onSkip;
  final String backLabel;
  final String nextLabel;
  final bool isNextEnabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: AppColors.card,
        boxShadow: AppShadows.navBar,
      ),
      child: Row(
        children: [
          // Bouton retour / annuler
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onBack,
              icon: const Icon(LucideIcons.arrow_left, size: 16),
              label: Text(backLabel),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.foreground,
                side: BorderSide(color: AppColors.border),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
              ),
            ),
          ),

          // Bouton Passer (optionnel)
          if (onSkip != null) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: onSkip,
              child: Text(
                'Passer',
                style: AppTypography.bodySmall(
                  color: AppColors.mutedForeground,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],

          const SizedBox(width: 12),

          // Bouton suivant / terminer
          Expanded(
            child: ElevatedButton.icon(
              onPressed: isNextEnabled ? onNext : null,
              icon: Icon(
                nextLabel == 'Terminer' || nextLabel == 'Enregistrer'
                    ? LucideIcons.save
                    : null,
                size: 16,
              ),
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(nextLabel),
                  if (nextLabel == 'Suivant') ...[
                    const SizedBox(width: 6),
                    const Icon(LucideIcons.arrow_right, size: 16),
                  ],
                ],
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.muted,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Définition d une étape du stepper.
class AppStepItem {
  const AppStepItem({required this.label, required this.icon});
  final String label;
  final IconData icon;
}
