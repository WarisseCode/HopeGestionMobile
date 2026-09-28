import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../core/config/app_config.dart';
import '../../../core/design_system.dart';
import '../data/biens_repository.dart';
import '../data/biens_results.dart';
import '../models/immeuble.dart';
import '../models/lot.dart';
import '../models/occupation_immeuble.dart';
import '../widgets/immeuble_card.dart';
import 'edit_immeuble_screen.dart';
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

  Future<void> _edit(Immeuble immeuble) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => EditImmeubleScreen(immeuble: immeuble)),
    );
    // `updateImmeuble` a rechargé `BiensRepository.immeubles` : reconstruire
    // pour relire l'immeuble à jour (cet écran n'écoute pas le dépôt).
    if (mounted) setState(() {});
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
      padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
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
          PopupMenuButton<String>(
            tooltip: 'Actions',
            icon: Icon(
              LucideIcons.ellipsis_vertical,
              size: 20,
              color: AppColors.foreground,
            ),
            color: AppColors.card,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.borderSm),
            onSelected: (action) {
              if (action == 'edit') _edit(immeuble);
              if (action == 'delete') _confirmDelete(immeuble);
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.file_pen,
                      size: 18,
                      color: AppColors.foreground,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Modifier',
                      style: AppTypography.body(color: AppColors.foreground),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(LucideIcons.trash, size: 18, color: AppColors.error),
                    const SizedBox(width: 10),
                    Text(
                      'Supprimer',
                      style: AppTypography.body(color: AppColors.error),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody(Immeuble immeuble) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final lots = _lots;
    final occupation = OccupationImmeuble.fromLots(
      lots,
      capacitePrevue: immeuble.totalLotsDeclares,
    );
    final description = immeuble.description?.trim() ?? '';

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
        children: [
          ImmeublePhotoGallery(photos: immeuble.galerie),
          const SizedBox(height: 16),

          _OccupationCard(occupation: occupation),
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

          if (description.isNotEmpty) ...[
            _CardContainer(
              title: 'DESCRIPTION',
              children: [
                Text(
                  description,
                  style: AppTypography.body(color: AppColors.foreground),
                ),
              ],
            ),
            const SizedBox(height: 14),
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
                value: immeuble.ownerNomAffiche ?? '—',
              ),
              Divider(color: AppColors.border, height: 1),
              _DetailRow(
                label: 'Gestionnaire',
                value: immeuble.gestionnaireName ?? 'Géré par le propriétaire',
              ),
            ],
          ),
          const SizedBox(height: 14),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'LOTS (${lots.length})',
                style: AppTypography.labelUppercase(
                  color: AppColors.mutedForeground,
                  fontSize: 10.5,
                ),
              ),
              if (lots.isNotEmpty)
                TextButton.icon(
                  onPressed: () => _addLot(immeuble),
                  icon: const Icon(LucideIcons.plus, size: 16),
                  label: const Text('Ajouter'),
                ),
            ],
          ),
          const SizedBox(height: 8),

          if (lots.isEmpty)
            _EmptyLots(onAdd: () => _addLot(immeuble))
          else
            ...lots.map(
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

/// Galerie d'en-tête : photo principale, défilement horizontal et
/// indicateur de pages si plusieurs photos, placeholder discret si aucune
/// (ou en cas d'erreur de chargement).
class ImmeublePhotoGallery extends StatefulWidget {
  const ImmeublePhotoGallery({super.key, required this.photos});

  final List<String> photos;

  static const double height = 180;

  @override
  State<ImmeublePhotoGallery> createState() => _ImmeublePhotoGalleryState();
}

class _ImmeublePhotoGalleryState extends State<ImmeublePhotoGallery> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final photos = widget.photos;

    return ClipRRect(
      borderRadius: AppRadius.borderMd,
      child: SizedBox(
        height: ImmeublePhotoGallery.height,
        child: photos.isEmpty
            ? _placeholder()
            : Stack(
                children: [
                  PageView.builder(
                    itemCount: photos.length,
                    onPageChanged: (i) => setState(() => _page = i),
                    itemBuilder: (_, i) => Image.network(
                      AppConfig.resolveFileUrl(photos[i]),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (_, _, _) => _placeholder(),
                    ),
                  ),
                  if (photos.length > 1)
                    Positioned(
                      right: 10,
                      bottom: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          // Pastille sombre fixe : reste lisible sur
                          // n'importe quelle photo, en clair comme en sombre.
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: AppRadius.borderFull,
                        ),
                        child: Text(
                          '${_page + 1} / ${photos.length}',
                          style: AppTypography.badge(color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _placeholder() {
    return ColoredBox(
      color: AppColors.secondary,
      child: Center(
        child: Icon(
          LucideIcons.building,
          size: 32,
          color: AppColors.primary.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}

/// Carte unique « Occupation » (fusion des anciennes cartes LOTS et
/// OCCUPATION) : état, lots occupés / créés, barre, capacité prévue et
/// revenu mensuel.
class _OccupationCard extends StatelessWidget {
  const _OccupationCard({required this.occupation});

  final OccupationImmeuble occupation;

  @override
  Widget build(BuildContext context) {
    final etat = EtatOccupationStyle.of(occupation.etat);

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'OCCUPATION',
                  style: AppTypography.labelUppercase(
                    color: AppColors.mutedForeground,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              AppBadge(
                label: etat.label,
                type: etat.badgeType,
                isUppercase: true,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  '${occupation.lotsOccupes} / ${occupation.lotsCrees} '
                  'occupé${occupation.lotsOccupes > 1 ? 's' : ''}',
                  style: AppTypography.titleScreen(fontSize: 18),
                ),
              ),
              Text(
                '${occupation.pourcentage} %',
                style: AppTypography.titleSection(
                  fontSize: 15,
                  color: etat.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: AppRadius.borderFull,
            child: LinearProgressIndicator(
              value: occupation.ratio,
              minHeight: 6,
              backgroundColor: AppColors.muted,
              valueColor: AlwaysStoppedAnimation(etat.color),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            occupation.libelleCapacite,
            style: AppTypography.caption(color: AppColors.mutedForeground),
          ),
          const SizedBox(height: 12),
          Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(LucideIcons.wallet, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Revenu mensuel',
                  style: AppTypography.bodySmall(
                    color: AppColors.mutedForeground,
                  ),
                ),
              ),
              Text(
                formatMontant(occupation.revenuMensuel),
                style: AppTypography.titleSection(fontSize: 15),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyLots extends StatelessWidget {
  const _EmptyLots({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(
            LucideIcons.key_round,
            size: 24,
            color: AppColors.primary.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 8),
          Text(
            'Aucun lot pour cet immeuble pour le moment.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall(color: AppColors.mutedForeground),
          ),
          const SizedBox(height: 14),
          // `AppButton` ne tronque pas son libellé : `scaleDown` le réduit
          // plutôt que de déborder sur un écran étroit ou avec une grande
          // taille de texte système (accessibilité).
          FittedBox(
            fit: BoxFit.scaleDown,
            child: AppButton.primary(
              label: 'Ajouter le premier lot',
              icon: const Icon(LucideIcons.plus, size: 18),
              isFullWidth: false,
              onPressed: onAdd,
            ),
          ),
        ],
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
          const SizedBox(width: 12),
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

/// Libellé et type de badge d'un statut de lot (valeurs backend :
/// `disponible`, `occupe`/`loue`, `reserve`, `vendu`, `hors_service`).
({String label, AppBadgeType type}) statutLot(String statut) =>
    switch (statut.toLowerCase()) {
      'occupe' || 'loue' => (label: 'Occupé', type: AppBadgeType.positive),
      'reserve' => (label: 'Réservé', type: AppBadgeType.info),
      'vendu' => (label: 'Vendu', type: AppBadgeType.neutral),
      'hors_service' => (label: 'Hors service', type: AppBadgeType.danger),
      'disponible' => (label: 'Disponible', type: AppBadgeType.warning),
      // Valeur inconnue (colonne texte libre) : affichée telle quelle.
      _ => (label: statut, type: AppBadgeType.neutral),
    };

/// « 1 560 000 F » — même format que `dashboard_data.dart` et
/// `locataire_detail_screen.dart` (copies privées là-bas, laissées
/// intactes : hors périmètre).
String formatMontant(double value) {
  final rounded = value.round();
  final isNegative = rounded < 0;
  final digits = rounded.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(' ');
    buffer.write(digits[i]);
  }
  return '${isNegative ? '-' : ''}$buffer F';
}

class _LotRow extends StatelessWidget {
  const _LotRow({required this.lot, this.onTap});

  final Lot lot;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isOccupe = OccupationImmeuble.estOccupe(lot);
    final statut = statutLot(lot.statut);
    final mainPhoto = lot.mainPhoto;
    final fallbackIcon = Icon(
      isOccupe ? LucideIcons.user : LucideIcons.key_round,
      size: 18,
      color: isOccupe ? AppColors.primary : AppColors.mutedForeground,
    );
    final sousTitre = [
      lot.etage,
      lot.type,
    ].where((s) => s != null && s.isNotEmpty).join(' · ');

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
                      errorBuilder: (_, _, _) => fallbackIcon,
                    )
                  : fallbackIcon,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lot.reference,
                  style: AppTypography.bodyMedium(
                    color: AppColors.foreground,
                  ).copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (sousTitre.isNotEmpty)
                  Text(
                    sousTitre,
                    style: AppTypography.caption(
                      color: AppColors.mutedForeground,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AppBadge(label: statut.label, type: statut.type),
              if (lot.loyer != null && lot.loyer! > 0) ...[
                const SizedBox(height: 4),
                Text(
                  formatMontant(lot.loyer!),
                  style: AppTypography.bodySmall(
                    color: AppColors.foreground,
                  ).copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
