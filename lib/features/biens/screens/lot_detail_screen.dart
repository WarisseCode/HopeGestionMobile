import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../core/config/app_config.dart';
import '../../../core/design_system.dart';
import '../data/biens_repository.dart';
import '../data/biens_results.dart';
import '../models/lot.dart';

/// Fiche détaillée d'un lot réel.
class LotDetailScreen extends StatefulWidget {
  const LotDetailScreen({super.key, required this.lot});

  final Lot lot;

  @override
  State<LotDetailScreen> createState() => _LotDetailScreenState();
}

class _LotDetailScreenState extends State<LotDetailScreen> {
  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ce lot ?'),
        content: Text(
          'Le lot « ${widget.lot.reference} » sera déplacé vers la corbeille.',
        ),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderLg),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Supprimer', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final result = await BiensRepository.instance.deleteLot(widget.lot.id);
    if (!mounted) return;

    switch (result) {
      case DeleteLotSuccess():
        Navigator.of(context).pop();
      case DeleteLotFailure(message: final message):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lot = widget.lot;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      LucideIcons.arrow_left,
                      color: AppColors.foreground,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      lot.reference,
                      style: AppTypography.titleScreen(fontSize: 20),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: _confirmDelete,
                    icon: Icon(
                      LucideIcons.trash,
                      size: 20,
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: [
                  if (lot.photos.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.network(
                        AppConfig.resolveFileUrl(lot.photos.first),
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _photoPlaceholder(),
                      ),
                    ),
                    if (lot.photos.length > 1) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 64,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: lot.photos.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemBuilder: (context, index) => ClipRRect(
                            borderRadius: AppRadius.borderMd,
                            child: Image.network(
                              AppConfig.resolveFileUrl(lot.photos[index]),
                              width: 64,
                              height: 64,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                width: 64,
                                height: 64,
                                color: AppColors.muted,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                  ],
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                      boxShadow: AppShadows.soft,
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _row('Immeuble', lot.immeubleNom),
                        _row('Type', lot.type),
                        _row('Étage', lot.etage),
                        _row('Bloc', lot.bloc),
                        _row(
                          'Superficie',
                          lot.superficie == null
                              ? null
                              : '${lot.superficie} m²',
                        ),
                        _row('Nombre de pièces', lot.nbPieces?.toString()),
                        _row(
                          'Loyer',
                          lot.loyer == null
                              ? null
                              : '${lot.loyer!.toStringAsFixed(0)} F CFA',
                        ),
                        _row(
                          'Charges',
                          lot.charges == null
                              ? null
                              : '${lot.charges!.toStringAsFixed(0)} F CFA',
                        ),
                        _row('Périodicité', lot.periodicite),
                        _row(
                          'Caution',
                          lot.caution == null
                              ? null
                              : '${lot.caution!.toStringAsFixed(0)} F CFA',
                        ),
                        _row('Avance', '${lot.avance} mois'),
                        _row('Statut', lot.statut, isLast: true),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _photoPlaceholder() {
    return Container(
      height: 180,
      color: AppColors.muted,
      child: Center(
        child: Icon(
          LucideIcons.image_off,
          size: 32,
          color: AppColors.mutedForeground,
        ),
      ),
    );
  }

  Widget _row(String label, String? value, {bool isLast = false}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: AppTypography.bodySmall(
                  color: AppColors.mutedForeground,
                ),
              ),
              Flexible(
                child: Text(
                  (value == null || value.isEmpty) ? '—' : value,
                  textAlign: TextAlign.right,
                  style: AppTypography.bodySmall(
                    color: AppColors.foreground,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        if (!isLast) Divider(color: AppColors.border, height: 1),
      ],
    );
  }
}
