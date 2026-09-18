import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../../core/design_system.dart';
import '../models/nouveau_locataire_form.dart';

/// Étape 4 : Récapitulatif et confirmation finale avant enregistrement.
class LocataireStep4Confirmation extends StatefulWidget {
  const LocataireStep4Confirmation({
    super.key,
    required this.form,
    required this.onGoToStep,
  });

  final NouveauLocataireForm form;
  final void Function(int step) onGoToStep;

  @override
  State<LocataireStep4Confirmation> createState() =>
      _LocataireStep4ConfirmationState();
}

class _LocataireStep4ConfirmationState
    extends State<LocataireStep4Confirmation> {
  @override
  Widget build(BuildContext context) {
    final f = widget.form;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ÉTAPE 4',
            style: AppTypography.labelUppercase(
              color: AppColors.mutedForeground,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Récapitulatif & Confirmation',
            style: AppTypography.titleScreen(),
          ),
          const SizedBox(height: 8),
          Text(
            'Vérifiez les données avant d\'enregistrer le profil.',
            style: AppTypography.bodySmall(color: AppColors.mutedForeground),
          ),
          const SizedBox(height: 24),

          // Carte Profil
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: AppRadius.borderMd,
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.positiveSoft,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          f.initials.isEmpty ? '?' : f.initials,
                          style: AppTypography.titleSection(
                            color: AppColors.primaryStrong,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            f.nomComplet.trim().isEmpty
                                ? 'NOM DU LOCATAIRE'
                                : f.nomComplet,
                            style: AppTypography.body(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${f.typeProfile} · ${f.nationalite.isEmpty ? 'Non renseigné' : f.nationalite}',
                            style: AppTypography.kpiNote(
                              color: AppColors.mutedForeground,
                            ),
                          ),
                          Text(
                            'Propriétaire : ${f.proprietaire.isEmpty ? 'Non assigné' : f.proprietaire}',
                            style: AppTypography.kpiNote(
                              color: AppColors.primaryStrong,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => widget.onGoToStep(0),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Modifier',
                        style: AppTypography.kpiNote(color: AppColors.primary)
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),

                // Grille 2x2 informations
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _InfoTile(
                        icon: LucideIcons.phone,
                        label: 'Téléphone',
                        value: f.telephone.isEmpty ? '—' : f.telephone,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _InfoTile(
                        icon: LucideIcons.mail,
                        label: 'Email',
                        value: f.email.isEmpty ? '—' : f.email,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _InfoTile(
                        icon: LucideIcons.credit_card,
                        label: 'Paiement',
                        value: f.modePaiement,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _InfoTile(
                        icon: LucideIcons.file_text,
                        label: 'Pièce d\'identité',
                        value: f.numeroId.isEmpty ? 'Non fournie' : f.numeroId,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Statut du profil
          AppDropdown<String>(
            label: 'Statut du profil',
            value: f.statut,
            items: NouveauLocataireForm.statuts
                .map((s) => AppDropdownItem(label: s, value: s))
                .toList(),
            onChanged: (v) => setState(() => f.statut = v ?? f.statut),
          ),
          const SizedBox(height: 20),

          // Bannière portail locataire
          const AppInfoBanner(
            text: 'Une invitation avec identifiants sécurisés sera transmise par SMS/Email une fois le bail activé.',
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: AppColors.mutedForeground),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTypography.kpiNote(
                color: AppColors.mutedForeground,
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTypography.bodySmall(
            color: AppColors.foreground,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
