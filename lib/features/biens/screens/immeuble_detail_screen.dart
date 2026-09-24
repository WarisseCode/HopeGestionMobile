import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../core/config/app_config.dart';
import '../../../core/design_system.dart';
import '../data/biens_repository.dart';
import '../data/biens_results.dart';
import '../models/immeuble.dart';
import '../models/lot.dart';
import 'lot_detail_screen.dart';
import 'nouveau_lot_screen.dart';

/// Fiche détaillée d'un immeuble réel + ses lots.
///
/// Pas de route `GET /immeubles/:id` côté backend (vérifié en phase 4.4,
/// §0) : l'immeuble est retrouvé localement dans `BiensRepository
/// .immeubles` (déjà chargée par `BiensScreen`), et ses lots filtrés
/// localement depuis `BiensRepository.lots` par `building_id` — pas de
/// route dédiée « lots d'un immeuble » non plus.
class ImmeubleDetailScreen extends StatefulWidget {
  const ImmeubleDetailScreen({super.key, required this.immeubleId});

  final int immeubleId;

  @override
  State<ImmeubleDetailScreen> createState() => _ImmeubleDetailScreenState();
}

class _ImmeubleDetailScreenState extends State<ImmeubleDetailScreen> {
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await BiensRepository.instance.listLots();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result is LotsListFailure) _error = result.message;
    });
  }

  Immeuble? get _immeuble {
    for (final i in BiensRepository.instance.immeubles) {
      if (i.id == widget.immeubleId) return i;
    }
    return null;
  }

  List<Lot> get _lots => BiensRepository.instance.lots
      .where((l) => l.buildingId == widget.immeubleId)
      .toList();

  Future<void> _addLot(Immeuble immeuble) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NouveauLotScreen(
          buildingId: immeuble.id,
          immeubleNom: immeuble.nom,
        ),
      ),
    );
    if (!mounted) return;
    await BiensRepository.instance.listLots();
  }

  Future<void> _confirmDelete(Immeuble immeuble) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer cet immeuble ?'),
        content: Text(
          'L\'immeuble « ${immeuble.nom} » sera déplacé vers la corbeille. '
          'Cette action ne fonctionne que si aucun lot n\'y est rattaché.',
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

    final result = await BiensRepository.instance.deleteImmeuble(immeuble.id);
    if (!mounted) return;

    switch (result) {
      case DeleteImmeubleSuccess():
        Navigator.of(context).pop();
      case DeleteImmeubleHasLots(message: final message):
        _showSnack(message, isError: true);
      case DeleteImmeubleFailure(message: final message):
        _showSnack(message, isError: true);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final immeuble = _immeuble;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: immeuble == null
            ? _buildNotFound()
            : Column(
                children: [
                  _buildTopBar(immeuble),
                  Expanded(child: _buildBody(immeuble)),
                ],
              ),
      ),
    );
  }

  Widget _buildNotFound() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(LucideIcons.arrow_left, color: AppColors.foreground),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: Text(
              'Immeuble introuvable.',
              style: AppTypography.bodySmall(color: AppColors.mutedForeground),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar(Immeuble immeuble) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(LucideIcons.arrow_left, color: AppColors.foreground),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              immeuble.nom,
              style: AppTypography.titleScreen(fontSize: 20),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            onPressed: () => _confirmDelete(immeuble),
            icon: Icon(LucideIcons.trash, size: 20, color: AppColors.error),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(Immeuble immeuble) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
        children: [
          Container(
            height: 140,
            decoration: BoxDecoration(
              color: AppColors.positiveSoft,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Center(
              child: Icon(
                LucideIcons.building,
                size: 56,
                color: AppColors.primary.withValues(alpha: 0.35),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              _MetricBox(
                label: 'LOTS',
                value: '${immeuble.lotsOccupes} / ${immeuble.nbLots}',
                subtext: 'occupés',
              ),
              const SizedBox(width: 8),
              _MetricBox(
                label: 'OCCUPATION',
                value: '${immeuble.occupationPercent}%',
                subtext: immeuble.etatOccupation ?? '—',
                highlight: true,
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warningSoft,
                borderRadius: AppRadius.borderMd,
              ),
              child: Text(
                'Lots : $_error',
                style: AppTypography.bodySmall(color: AppColors.warning),
              ),
            ),
            const SizedBox(height: 16),
          ],

          _CardContainer(
            title: 'CARACTÉRISTIQUES',
            children: [
              _DetailRow(label: 'Type', value: immeuble.type ?? '—'),
              Divider(color: AppColors.border, height: 1),
              _DetailRow(
                label: 'Adresse',
                value: [
                  immeuble.adresse,
                  immeuble.quartier,
                  immeuble.ville,
                  immeuble.pays,
                ].where((s) => s != null && s.isNotEmpty).join(', '),
              ),
              Divider(color: AppColors.border, height: 1),
              _DetailRow(
                label: 'Étages',
                value: immeuble.nombreEtages?.toString() ?? '—',
              ),
              Divider(color: AppColors.border, height: 1),
              _DetailRow(
                label: 'Propriétaire',
                value: immeuble.ownerName ?? '—',
              ),
              Divider(color: AppColors.border, height: 1),
              _DetailRow(
                label: 'Gestionnaire',
                value:
                    immeuble.gestionnaireName ?? 'Géré par le propriétaire',
              ),
            ],
          ),
          const SizedBox(height: 14),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'LOTS (${_lots.length})',
                style: AppTypography.labelUppercase(
                  color: AppColors.mutedForeground,
                  fontSize: 10.5,
                ),
              ),
              TextButton.icon(
                onPressed: () => _addLot(immeuble),
                icon: const Icon(LucideIcons.plus, size: 16),
                label: const Text('Ajouter'),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (_lots.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: AppRadius.borderMd,
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                'Aucun lot pour cet immeuble pour le moment.',
                style: AppTypography.bodySmall(
                  color: AppColors.mutedForeground,
                ),
              ),
            )
          else
            ..._lots.map(
              (lot) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _LotRow(
                  lot: lot,
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => LotDetailScreen(lot: lot),
                      ),
                    );
                    if (!mounted) return;
                    await BiensRepository.instance.listLots();
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MetricBox extends StatelessWidget {
  const _MetricBox({
    required this.label,
    required this.value,
    required this.subtext,
    this.highlight = false,
  });

  final String label;
  final String value;
  final String subtext;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: highlight ? AppColors.positiveSoft : AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: highlight
                ? AppColors.primary.withValues(alpha: 0.2)
                : AppColors.border,
          ),
          boxShadow: AppShadows.soft,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTypography.labelUppercase(
                fontSize: 9,
                color: AppColors.mutedForeground,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: AppTypography.titleScreen(
                fontSize: 16,
                color: highlight ? AppColors.primary : AppColors.foreground,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              subtext,
              style: AppTypography.caption(color: AppColors.mutedForeground),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardContainer extends StatelessWidget {
  const _CardContainer({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Text(
            title,
            style: AppTypography.labelUppercase(
              color: AppColors.mutedForeground,
              fontSize: 10.5,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodySmall(color: AppColors.mutedForeground),
          ),
          Flexible(
            child: Text(
              value.isEmpty ? '—' : value,
              textAlign: TextAlign.right,
              style: AppTypography.bodySmall(
                color: AppColors.foreground,
              ).copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _LotRow extends StatelessWidget {
  const _LotRow({required this.lot, this.onTap});

  final Lot lot;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isOccupe = lot.statut == 'occupe';
    final mainPhoto = lot.mainPhoto;
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          ClipOval(
            child: Container(
              width: 38,
              height: 38,
              color: isOccupe ? AppColors.positiveSoft : AppColors.muted,
              child: mainPhoto != null
                  ? Image.network(
                      AppConfig.resolveFileUrl(mainPhoto),
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Icon(
                        isOccupe ? LucideIcons.user : LucideIcons.key_round,
                        size: 18,
                        color: isOccupe
                            ? AppColors.primary
                            : AppColors.mutedForeground,
                      ),
                    )
                  : Icon(
                      isOccupe ? LucideIcons.user : LucideIcons.key_round,
                      size: 18,
                      color: isOccupe
                          ? AppColors.primary
                          : AppColors.mutedForeground,
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lot.reference,
                  style: AppTypography.bodyMedium(color: AppColors.foreground)
                      .copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  [lot.etage, lot.type, lot.statut]
                      .where((s) => s != null && s.isNotEmpty)
                      .join(' · '),
                  style: AppTypography.caption(
                    color: AppColors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          if (lot.loyer != null)
            Text(
              '${lot.loyer!.toStringAsFixed(0)} F',
              style: AppTypography.bodySmall(color: AppColors.foreground)
                  .copyWith(fontWeight: FontWeight.bold),
            ),
        ],
      ),
    );
  }
}
