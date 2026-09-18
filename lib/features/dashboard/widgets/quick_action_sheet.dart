import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../core/design_system.dart';
import '../../../core/i18n/app_strings.dart';
import '../../biens/screens/nouveau_bien_screen.dart';
import '../../locataires/screens/nouveau_locataire_screen.dart';
import '../../finances/screens/depense_screen.dart';
import '../../documents/screens/nouvelle_quittance_screen.dart';
import '../../documents/screens/nouveau_contrat_screen.dart';
import '../../documents/screens/nouvel_etat_des_lieux_screen.dart';

class QuickActionOption {
  final String id;
  final String label;
  final IconData icon;

  const QuickActionOption({
    required this.id,
    required this.label,
    required this.icon,
  });
}

/// Modale « ACTION RAPIDE / Que créer ? » conforme à la maquette 02-action-rapide.png
class QuickActionSheet extends StatelessWidget {
  final ValueChanged<String>? onOptionSelected;

  static const List<QuickActionOption> options = [
    QuickActionOption(
      id: 'property',
      label: 'Un bien',
      icon: LucideIcons.building,
    ),
    QuickActionOption(
      id: 'tenant',
      label: 'Un locataire',
      icon: LucideIcons.user_plus,
    ),
    QuickActionOption(
      id: 'invoice',
      label: 'Une facture',
      icon: LucideIcons.file_text,
    ),
    QuickActionOption(
      id: 'receipt',
      label: 'Une quittance',
      icon: LucideIcons.receipt,
    ),
    QuickActionOption(
      id: 'contract',
      label: 'Un contrat',
      icon: LucideIcons.file_pen,
    ),
    QuickActionOption(
      id: 'inventory',
      label: 'Un état des lieux',
      icon: LucideIcons.camera,
    ),
  ];

  const QuickActionSheet({super.key, this.onOptionSelected});

  /// Méthode utilitaire pour afficher la BottomSheet
  static Future<String?> show(BuildContext context) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => QuickActionSheet(
        onOptionSelected: (id) => Navigator.of(context).pop(id),
      ),
    );
  }

  /// Ouvre la modale puis navigue directement vers l'écran sélectionné
  static Future<void> showAndNavigate(BuildContext context) async {
    final selectedId = await show(context);
    if (selectedId != null && context.mounted) {
      navigateToAction(context, selectedId);
    }
  }

  /// Routeur central pour toutes les options d'action rapide
  static void navigateToAction(BuildContext context, String actionId) {
    Widget? screen;
    switch (actionId) {
      case 'property':
        screen = const NouveauBienScreen();
        break;
      case 'tenant':
        screen = const NouveauLocataireScreen();
        break;
      case 'invoice':
        screen = const DepenseScreen();
        break;
      case 'receipt':
        screen = const NouvelleQuittanceScreen();
        break;
      case 'contract':
        screen = const NouveauContratScreen();
        break;
      case 'inventory':
        screen = const NouvelEtatDesLieuxScreen();
        break;
    }
    if (screen != null) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen!));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Poignée de glissement (Drag Handle)
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: AppRadius.borderFull,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // En-tête : Titre & Fermeture
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.t('ACTION RAPIDE'),
                    style: AppTypography.labelUppercase(
                      fontSize: 10.5,
                      color: AppColors.mutedForeground,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppStrings.t('Que créer ?'),
                    style: AppTypography.titleScreen(fontSize: 20),
                  ),
                ],
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(
                  LucideIcons.x,
                  size: 18,
                  color: AppColors.mutedForeground,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Grille 2 colonnes x 3 lignes
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: options.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.3,
            ),
            itemBuilder: (context, index) {
              final option = options[index];
              return _ActionCard(
                option: option,
                onTap: () => onOptionSelected?.call(option.id),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final QuickActionOption option;
  final VoidCallback onTap;

  const _ActionCard({required this.option, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.borderLg,
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.borderLg,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.positiveSoft,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(option.icon, color: AppColors.primary, size: 19),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    AppStrings.t(option.label),
                    style: AppTypography.bodyMedium(
                      fontSize: 12.5,
                      color: AppColors.foreground,
                    ).copyWith(fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
