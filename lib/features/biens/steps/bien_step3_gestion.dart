import 'package:flutter/material.dart';

import '../../../../core/design_system.dart';
import '../models/nouveau_bien_form.dart';

/// Étape 3 : Gestion du bien (propriétaire, gestionnaire) + récapitulatif partiel.
class BienStep3Gestion extends StatefulWidget {
  const BienStep3Gestion({super.key, required this.form});
  final NouveauBienForm form;

  @override
  State<BienStep3Gestion> createState() => _BienStep3GestionState();
}

class _BienStep3GestionState extends State<BienStep3Gestion> {
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
          Text('Gestion du bien', style: AppTypography.titleScreen()),
          const SizedBox(height: 24),

          AppDropdown<String>(
            label: 'Propriétaire',
            isRequired: true,
            hintText: 'Sélectionner un propriétaire...',
            value: f.proprietaire.isEmpty ? null : f.proprietaire,
            items: NouveauBienForm.proprietaires
                .map((p) => AppDropdownItem(label: p, value: p))
                .toList(),
            onChanged: (v) => setState(() => f.proprietaire = v ?? ''),
          ),
          const SizedBox(height: 20),

          AppDropdown<String>(
            label: 'Gestionnaire',
            value: f.gestionnaire,
            items: NouveauBienForm.gestionnaires
                .map((g) => AppDropdownItem(label: g, value: g))
                .toList(),
            onChanged: (v) => setState(() => f.gestionnaire = v ?? ''),
          ),
          const SizedBox(height: 6),
          Text(
            'Choisissez « Géré directement par le propriétaire » si personne ne gère le bien',
            style: AppTypography.kpiNote(
              color: AppColors.mutedForeground,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 28),

          // Récapitulatif partiel
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.positiveSoft,
              borderRadius: AppRadius.borderMd,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RÉCAPITULATIF PARTIEL',
                  style: AppTypography.labelUppercase(
                    color: AppColors.primaryStrong,
                    fontSize: 9.5,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _RecapItem(
                        label: 'Nom',
                        value: f.nom.isEmpty ? '—' : f.nom,
                      ),
                    ),
                    Expanded(
                      child: _RecapItem(
                        label: 'Type',
                        value: f.type.isEmpty ? '—' : f.type,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _RecapItem(
                        label: 'Localisation',
                        value: f.ville.isEmpty ? '—' : f.ville,
                      ),
                    ),
                    Expanded(
                      child: _RecapItem(
                        label: 'Lots',
                        value: f.nbLots == 0 ? '—' : f.nbLots.toString(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecapItem extends StatelessWidget {
  const _RecapItem({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.kpiNote(
            color: AppColors.primaryStrong,
            fontSize: 10.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTypography.bodySmall(
            color: AppColors.primaryStrong,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
