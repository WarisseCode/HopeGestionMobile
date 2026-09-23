import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../../core/design_system.dart';
import '../../locataires/models/owner.dart';
import '../models/nouveau_immeuble_form.dart';

/// Étape 3 : Propriétaire de rattachement + récapitulatif partiel.
///
/// Pas de sélecteur `gestionnaire_id` dans cette phase (demande explicite) :
/// `gestionnaire_id` reste optionnel et jamais envoyé — équivalent à « Géré
/// directement par le propriétaire » côté web. Un sélecteur dédié pourra
/// être ajouté plus tard quand `GET /api/compte/utilisateurs` sera branché.
class ImmeubleStep3Proprietaire extends StatefulWidget {
  const ImmeubleStep3Proprietaire({
    super.key,
    required this.form,
    required this.owners,
    required this.ownersLoading,
    required this.ownersError,
    required this.onRetryOwners,
  });

  final NouveauImmeubleForm form;
  final List<Owner> owners;
  final bool ownersLoading;
  final String? ownersError;
  final VoidCallback onRetryOwners;

  @override
  State<ImmeubleStep3Proprietaire> createState() =>
      _ImmeubleStep3ProprietaireState();
}

class _ImmeubleStep3ProprietaireState
    extends State<ImmeubleStep3Proprietaire> {
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
          Text('Propriétaire', style: AppTypography.titleScreen()),
          const SizedBox(height: 24),

          _buildOwnerField(f),
          const SizedBox(height: 28),

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
                      child: _RecapItem(label: 'Type', value: f.type),
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
                        label: 'Capacité prévue',
                        value: f.totalLots == null
                            ? '—'
                            : '${f.totalLots} lot(s)',
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

  /// Même mécanisme réel que `LocataireStep1Identite._buildOwnerField` :
  /// `GET /owners`, résolu automatiquement par `tenantGuard.ts` si un seul
  /// propriétaire est géré, sélection obligatoire si plusieurs.
  Widget _buildOwnerField(NouveauImmeubleForm f) {
    if (widget.ownersLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (widget.ownersError != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.warningSoft,
          borderRadius: AppRadius.borderMd,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Propriétaires : ${widget.ownersError}',
                style: AppTypography.bodySmall(color: AppColors.warning),
              ),
            ),
            TextButton(
              onPressed: widget.onRetryOwners,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (widget.owners.isEmpty) {
      return const SizedBox.shrink();
    }

    if (widget.owners.length == 1) {
      final only = widget.owners.first;
      return Row(
        children: [
          Icon(LucideIcons.building, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Propriétaire : ${only.displayName}',
              style: AppTypography.bodySmall(color: AppColors.foreground),
            ),
          ),
        ],
      );
    }

    return AppDropdown<int>(
      label: 'Propriétaire',
      isRequired: true,
      hintText: 'Sélectionner un propriétaire...',
      value: f.ownerId,
      items: widget.owners
          .map((o) => AppDropdownItem(label: o.displayName, value: o.id))
          .toList(),
      onChanged: (v) => setState(() {
        f.ownerId = v;
        f.ownerName = widget.owners.firstWhere((o) => o.id == v).displayName;
      }),
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
