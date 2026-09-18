import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../../core/design_system.dart';
import '../models/nouveau_locataire_form.dart';

/// Étape 3 : Modalités financières et moyens de paiement (facultative).
class LocataireStep3Finances extends StatefulWidget {
  const LocataireStep3Finances({super.key, required this.form});
  final NouveauLocataireForm form;

  @override
  State<LocataireStep3Finances> createState() => _LocataireStep3FinancesState();
}

class _LocataireStep3FinancesState extends State<LocataireStep3Finances> {
  static const List<_PaymentOption> _options = [
    _PaymentOption(
      title: 'Mobile Money',
      subtitle: 'MTN, Moov, Wave, Orange',
      icon: LucideIcons.smartphone,
    ),
    _PaymentOption(
      title: 'Espèces',
      subtitle: 'Règlement en main propre',
      icon: LucideIcons.banknote,
    ),
    _PaymentOption(
      title: 'Virement',
      subtitle: 'Compte bancaire professionnel',
      icon: LucideIcons.building,
    ),
    _PaymentOption(
      title: 'Chèque',
      subtitle: 'Chèque de banque certifié',
      icon: LucideIcons.file_check,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final f = widget.form;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ÉTAPE 3',
            style: AppTypography.labelUppercase(
              color: AppColors.mutedForeground,
            ),
          ),
          const SizedBox(height: 4),
          Text('Modalités financières', style: AppTypography.titleScreen()),
          const SizedBox(height: 8),
          Text(
            'Configurez les préférences de règlement par défaut.',
            style: AppTypography.bodySmall(color: AppColors.mutedForeground),
          ),
          const SizedBox(height: 20),

          const AppInfoBanner(
            text: 'Ces options sont indicatives. Les montants exacts de loyers et cautions seront paramétrés lors de la signature du bail.',
          ),
          const SizedBox(height: 24),

          Text(
            'Mode de paiement privilégié',
            style: AppTypography.labelField(),
          ),
          const SizedBox(height: 12),

          // Grille 2x2
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.25,
            ),
            itemCount: _options.length,
            itemBuilder: (context, index) {
              final opt = _options[index];
              final isSelected = f.modePaiement == opt.title;

              return InkWell(
                onTap: () {
                  setState(() => f.modePaiement = opt.title);
                },
                borderRadius: AppRadius.borderMd,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.positiveSoft : AppColors.card,
                    borderRadius: AppRadius.borderMd,
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(
                            opt.icon,
                            size: 24,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.mutedForeground,
                          ),
                          if (isSelected)
                            Icon(
                              LucideIcons.circle_check,
                              size: 16,
                              color: AppColors.primary,
                            ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        opt.title,
                        style: AppTypography.body(
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: isSelected
                              ? AppColors.primaryStrong
                              : AppColors.foreground,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        opt.subtitle,
                        style: AppTypography.kpiNote(
                          color: AppColors.mutedForeground,
                          fontSize: 10,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 28),

          // Switch paiement échelonné
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: AppRadius.borderMd,
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.split, size: 22, color: AppColors.primary),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Paiement échelonné autorisé',
                        style: AppTypography.body(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Permet au locataire de régler ses loyers en plusieurs tranches',
                        style: AppTypography.kpiNote(
                          color: AppColors.mutedForeground,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: f.paiementEchelonne,
                  activeTrackColor: AppColors.primary,
                  onChanged: (val) {
                    setState(() => f.paiementEchelonne = val);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentOption {
  const _PaymentOption({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;
}
