import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../core/config/app_config.dart';
import '../../../core/design_system.dart';
import '../../documents/data/baux_repository.dart';
import '../../documents/data/baux_results.dart';
import '../../documents/models/bail_resume.dart';
import '../../documents/screens/bail_detail_screen.dart';
import '../../finances/models/finance_format.dart';
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
  /// Bail en cours du lot (carte « Occupant actuel »). Chargé à part : un
  /// échec n'empêche jamais l'affichage du reste de la fiche.
  late Future<BailActifResult> _bailActif;

  @override
  void initState() {
    super.initState();
    _bailActif = _chargerBailActif();
  }

  Future<BailActifResult> _chargerBailActif() =>
      BauxRepository.instance.getBailActifDuLot(widget.lot.id);

  void _rechargerBailActif() {
    setState(() {
      _bailActif = _chargerBailActif();
    });
  }

  /// La fiche bail est en lecture seule, mais l'utilisateur a pu naviguer
  /// ailleurs depuis : rechargement prudent au retour.
  Future<void> _ouvrirBail(int bailId) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => BailDetailScreen(bailId: bailId)));
    if (!mounted) return;
    _rechargerBailActif();
  }

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
                  const SizedBox(height: 16),
                  FutureBuilder<BailActifResult>(
                    future: _bailActif,
                    // Au rechargement, FutureBuilder conserve le résultat
                    // précédent : un occupant déjà affiché le reste (pas de
                    // clignotement au retour de la fiche bail) ; tout autre
                    // état (ex. « Réessayer ») repasse par le chargement.
                    builder: (context, snapshot) {
                      final data = snapshot.data;
                      final enCours =
                          snapshot.connectionState != ConnectionState.done;
                      return _occupant(
                        enCours && data is! BailActifTrouve ? null : data,
                        lot,
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _occupant(BailActifResult? result, Lot lot) {
    switch (result) {
      case null:
        return _occupantCard(
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        );
      case BailActifTrouve(bail: final bail):
        return _occupantCard(
          onTap: () => _ouvrirBail(bail.id),
          child: _occupantTrouve(bail),
        );
      case LotSansBailActif():
        // `Lot.statut` reste la source de vérité du statut affiché plus
        // haut : l'incohérence est seulement signalée ici.
        if (lot.statut == 'occupe') {
          return _occupantCard(
            child: _occupantMessage(
              'Bail introuvable : ce lot est indiqué occupé, mais aucun '
              'bail en cours n\'est visible.',
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Aucun bail en cours',
            style: AppTypography.bodySmall(color: AppColors.mutedForeground),
          ),
        );
      case BailActifAccesRefuse():
        return _occupantCard(
          child: _occupantMessage(
            'Occupant non disponible : accès aux baux refusé.',
          ),
        );
      case BailActifNetworkError():
        return _occupantCard(
          child: _occupantMessage(
            'Connexion impossible : occupant non chargé.',
            onRetry: _rechargerBailActif,
          ),
        );
      case BailActifFailure():
        return _occupantCard(
          child: _occupantMessage(
            'Occupant non chargé : une erreur est survenue.',
            onRetry: _rechargerBailActif,
          ),
        );
    }
  }

  Widget _occupantCard({required Widget child, VoidCallback? onTap}) {
    return Material(
      key: const Key('lot_occupant_card'),
      color: AppColors.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('OCCUPANT ACTUEL', style: AppTypography.labelUppercase()),
              const SizedBox(height: 10),
              child,
            ],
          ),
        ),
      ),
    );
  }

  Widget _occupantTrouve(BailResume bail) {
    final details = [
      if (bail.referenceBail != null) bail.referenceBail!,
      if (bail.loyerMensuel != null)
        '${formatMontant(bail.loyerMensuel!)}/mois',
      if (bail.dateDebut != null)
        'depuis le ${formatDateLongue(bail.dateDebut!)}',
    ].join(' · ');
    return Row(
      children: [
        _occupantAvatar(bail),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                bail.locataireNomComplet ?? 'Locataire',
                style: AppTypography.body(color: AppColors.foreground)
                    .copyWith(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
              if (bail.locataireTelephone != null) ...[
                const SizedBox(height: 2),
                Text(
                  bail.locataireTelephone!,
                  style: AppTypography.bodySmall(),
                ),
              ],
              if (details.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(details, style: AppTypography.caption()),
              ],
            ],
          ),
        ),
        Icon(
          LucideIcons.chevron_right,
          size: 18,
          color: AppColors.mutedForeground,
        ),
      ],
    );
  }

  /// Photo si renseignée, repli sur les initiales — même pattern que la
  /// fiche locataire.
  Widget _occupantAvatar(BailResume bail) {
    final photo = bail.locatairePhoto;
    if (photo == null) return _occupantInitiales(bail);
    return ClipOval(
      child: Image.network(
        AppConfig.resolveFileUrl(photo),
        width: 44,
        height: 44,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _occupantInitiales(bail),
      ),
    );
  }

  Widget _occupantInitiales(BailResume bail) {
    final initiales = [
      bail.locataireNom,
      bail.locatairePrenoms,
    ].whereType<String>().map((s) => s[0].toUpperCase()).join();
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.positiveSoft,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initiales.isEmpty ? '?' : initiales,
          style: AppTypography.bodyMedium(color: AppColors.primary)
              .copyWith(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _occupantMessage(String message, {VoidCallback? onRetry}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            message,
            style: AppTypography.bodySmall(color: AppColors.mutedForeground),
          ),
        ),
        if (onRetry != null)
          TextButton(onPressed: onRetry, child: const Text('Réessayer')),
      ],
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
