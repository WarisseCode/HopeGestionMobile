import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../core/config/app_config.dart';
import '../../../core/design_system.dart';
import '../../documents/screens/bail_detail_screen.dart';
import '../../finances/screens/encaisser_screen.dart';
import '../data/locataire_results.dart';
import '../data/locataires_repository.dart';
import '../models/locataire.dart';
import 'edit_locataire_screen.dart';

/// Fiche détaillée d'un locataire réel — `GET /api/locataires/:id`
/// (locataire + baux + paiements récents).
class LocataireDetailScreen extends StatefulWidget {
  final int locataireId;

  const LocataireDetailScreen({super.key, required this.locataireId});

  @override
  State<LocataireDetailScreen> createState() => _LocataireDetailScreenState();
}

class _LocataireDetailScreenState extends State<LocataireDetailScreen> {
  int _selectedTab = 0; // 0: Location, 1: Paiements, 2: Pièces

  bool _loading = true;
  String? _errorMessage;
  Locataire? _locataire;
  List<TenantLease> _baux = [];
  List<TenantPayment> _paiements = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    final result = await LocatairesRepository.instance.getDetail(
      widget.locataireId,
    );
    if (!mounted) return;
    switch (result) {
      case LocataireDetailSuccess(
        locataire: final locataire,
        baux: final baux,
        paiements: final paiements,
      ):
        setState(() {
          _locataire = locataire;
          _baux = baux;
          _paiements = paiements;
          _loading = false;
        });
      case LocataireDetailFailure(message: final message):
        setState(() {
          _errorMessage = message;
          _loading = false;
        });
    }
  }

  Future<void> _confirmDelete() async {
    final locataire = _locataire;
    if (locataire == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Supprimer ce locataire ?',
          style: AppTypography.titleScreen(fontSize: 19),
        ),
        content: Text(
          '« ${locataire.displayName} » sera déplacé vers la corbeille.',
          style: AppTypography.bodySmall(color: AppColors.mutedForeground),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Annuler',
              style: AppTypography.bodySmall(color: AppColors.mutedForeground),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text(
              'Supprimer',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final result = await LocatairesRepository.instance.delete(locataire.id);
    if (!mounted) return;
    switch (result) {
      case DeleteLocataireSuccess():
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Locataire déplacé vers la corbeille.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      case DeleteLocataireFailure(message: final message):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_errorMessage != null || _locataire == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Impossible de charger ce locataire',
                    textAlign: TextAlign.center,
                    style: AppTypography.titleScreen(fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage ?? 'Erreur inconnue.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmall(
                      color: AppColors.mutedForeground,
                    ),
                  ),
                  const SizedBox(height: 20),
                  AppButton.primary(
                    label: 'Réessayer',
                    onPressed: _load,
                    isFullWidth: false,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final locataire = _locataire!;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
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
                      locataire.displayName,
                      style: AppTypography.titleScreen(fontSize: 20),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: () async {
                      final updated = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) =>
                              EditLocataireScreen(locataire: locataire),
                        ),
                      );
                      if (updated == true) _load();
                    },
                    icon: Icon(
                      LucideIcons.pencil,
                      size: 20,
                      color: AppColors.primary,
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
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                children: [
                  // Carte Contact Principale
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                      boxShadow: AppShadows.soft,
                    ),
                    child: Row(
                      children: [
                        _avatar(locataire),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      locataire.displayName,
                                      style: AppTypography.titleScreen(
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.positiveSoft,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      locataire.statut.toUpperCase(),
                                      style: AppTypography.caption(
                                        color: AppColors.primaryStrong,
                                      ).copyWith(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                locataire.type,
                                style: AppTypography.bodySmall(
                                  color: AppColors.mutedForeground,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                [
                                  locataire.telephonePrincipal,
                                  if (locataire.email != null &&
                                      locataire.email!.isNotEmpty)
                                    locataire.email!,
                                ].join(' · '),
                                style: AppTypography.caption(
                                  color: AppColors.mutedForeground,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Situation des loyers (réelle, depuis le bail actif le
                  // plus récent — pas de prochaine échéance affichée : cette
                  // route ne renvoie pas le jour d'échéance par bail).
                  if (_activeBailPaymentStatus() != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.positiveSoft,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.circle_check,
                            color: AppColors.positive,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Situation des loyers : ${_paymentStatusLabel(_activeBailPaymentStatus())}',
                              style: AppTypography.bodyMedium(
                                color: AppColors.foreground,
                              ).copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Onglets
                  Row(
                    children: [
                      _ContactTab(
                        label: 'Contrat & Bail',
                        isSelected: _selectedTab == 0,
                        onTap: () => setState(() => _selectedTab = 0),
                      ),
                      const SizedBox(width: 8),
                      _ContactTab(
                        label: 'Paiements',
                        isSelected: _selectedTab == 1,
                        onTap: () => setState(() => _selectedTab = 1),
                      ),
                      const SizedBox(width: 8),
                      _ContactTab(
                        label: 'Pièces & Docs',
                        isSelected: _selectedTab == 2,
                        onTap: () => setState(() => _selectedTab = 2),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Contenu onglets
                  if (_selectedTab == 0) ...[
                    _buildBauxTab(),
                  ] else if (_selectedTab == 1) ...[
                    _buildPaiementsTab(),
                  ] else ...[
                    _buildDocumentsTab(locataire),
                  ],
                ],
              ),
            ),

            // Bouton Encaisser en bas
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: AppColors.card,
                border: Border(top: BorderSide(color: AppColors.border)),
                boxShadow: AppShadows.soft,
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context)
                        .push(
                          MaterialPageRoute(
                            builder: (_) =>
                                EncaisserScreen(locataireId: locataire.id),
                          ),
                        )
                        // Recharge dans tous les cas (encaissement réussi ou
                        // simple retour) : lecture idempotente, jamais coûteuse
                        // à tort — même politique que BiensScreen après une
                        // fiche immeuble.
                        .then((_) => _load());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(
                    LucideIcons.circle_dollar_sign,
                    color: Colors.white,
                    size: 18,
                  ),
                  label: const Text(
                    'Encaisser un loyer pour ce locataire',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Photo si renseignée (`AppConfig.resolveFileUrl` — chemin relatif tant
  /// que Digital Ocean Spaces n'est pas configuré, voir T-031), repli sur
  /// les initiales si absente ou en cas d'erreur de chargement — même
  /// pattern que `ImmeubleCard`/`_LotRow`.
  Widget _avatar(Locataire locataire) {
    final photo = locataire.photoProfilUrl;
    if (photo == null || photo.isEmpty) {
      return _initialsAvatar(locataire);
    }
    return ClipOval(
      child: Image.network(
        AppConfig.resolveFileUrl(photo),
        width: 58,
        height: 58,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _initialsAvatar(locataire),
      ),
    );
  }

  Widget _initialsAvatar(Locataire locataire) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: AppColors.positiveSoft,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          locataire.initials,
          style: AppTypography.titleScreen(
            fontSize: 22,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  String? _activeBailPaymentStatus() {
    if (_baux.isEmpty) return null;
    final active = _baux.where((b) => b.statut == 'actif' || b.statut == 'signe');
    final bail = active.isNotEmpty ? active.first : _baux.first;
    return bail.paymentStatus;
  }

  String _paymentStatusLabel(String? status) {
    switch (status) {
      case 'paid':
        return 'À jour';
      case 'late':
        return 'En retard';
      case 'pending':
        return 'En attente';
      default:
        return 'Inconnue';
    }
  }

  Widget _buildBauxTab() {
    if (_baux.isEmpty) {
      return _EmptyState(text: 'Aucun bail enregistré pour ce locataire.');
    }
    return _DetailCard(
      title: 'BAUX',
      children: [
        for (int i = 0; i < _baux.length; i++) ...[
          _DetailLine(
            label: [
              if (_baux[i].refLot != null) _baux[i].refLot!,
              if (_baux[i].buildingName != null) _baux[i].buildingName!,
            ].join(' — ').ifEmpty('Logement'),
            value: _baux[i].loyerActuel != null
                ? '${_formatMontant(_baux[i].loyerActuel!)} · ${_baux[i].statut}'
                : _baux[i].statut,
            onTap: () => _ouvrirBail(_baux[i].id),
          ),
          if (i < _baux.length - 1) Divider(color: AppColors.border, height: 1),
        ],
      ],
    );
  }

  /// La fiche du bail permet de résilier, renouveler ou signer : l'onglet
  /// « Contrat & Bail » peut être périmé au retour, d'où un rechargement
  /// systématique (lecture idempotente) — même pattern que `LotDetailScreen`.
  Future<void> _ouvrirBail(int bailId) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => BailDetailScreen(bailId: bailId)));
    if (!mounted) return;
    await _load();
  }

  Widget _buildPaiementsTab() {
    if (_paiements.isEmpty) {
      return _EmptyState(text: 'Aucun paiement enregistré.');
    }
    return _DetailCard(
      title: 'HISTORIQUE DES ENCAISSEMENTS',
      children: [
        for (int i = 0; i < _paiements.length; i++) ...[
          _PaymentLine(
            title: _paiements[i].type ?? 'Paiement',
            date: [
              if (_paiements[i].datePaiement != null)
                _paiements[i].datePaiement!,
              if (_paiements[i].modePaiement != null)
                _paiements[i].modePaiement!,
            ].join(' · '),
            amount: _formatMontant(_paiements[i].montant),
          ),
          if (i < _paiements.length - 1)
            Divider(color: AppColors.border, height: 1),
        ],
      ],
    );
  }

  Widget _buildDocumentsTab(Locataire locataire) {
    final hasPiece = (locataire.numeroPiece != null &&
            locataire.numeroPiece!.isNotEmpty) ||
        (locataire.typePiece != null && locataire.typePiece!.isNotEmpty);
    if (!hasPiece) {
      return _EmptyState(text: 'Aucune pièce d\'identité enregistrée.');
    }
    return _DetailCard(
      title: 'PIÈCE D\'IDENTITÉ',
      children: [
        _DetailLine(
          label: 'Type',
          value: locataire.typePiece ?? 'Non renseigné',
        ),
        Divider(color: AppColors.border, height: 1),
        _DetailLine(
          label: 'Numéro',
          value: locataire.numeroPiece ?? 'Non renseigné',
        ),
        if (locataire.dateExpirationPiece != null) ...[
          Divider(color: AppColors.border, height: 1),
          _DetailLine(
            label: 'Expiration',
            value: locataire.dateExpirationPiece!,
          ),
        ],
      ],
    );
  }
}

String _formatMontant(double value) {
  final rounded = value.round();
  final digits = rounded.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(' ');
    buffer.write(digits[i]);
  }
  return '$buffer F';
}

extension _IfEmpty on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          text,
          style: AppTypography.bodySmall(color: AppColors.mutedForeground),
        ),
      ),
    );
  }
}

class _ContactTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ContactTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.foreground,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 12.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _DetailCard({required this.title, required this.children});

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

class _DetailLine extends StatelessWidget {
  final String label;
  final String value;

  /// Ligne cliquable (chevron affiché) si renseigné.
  final VoidCallback? onTap;

  const _DetailLine({required this.label, required this.value, this.onTap});

  @override
  Widget build(BuildContext context) {
    final ligne = Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTypography.bodySmall(color: AppColors.mutedForeground),
            ),
          ),
          Text(
            value,
            style: AppTypography.bodySmall(color: AppColors.foreground)
                .copyWith(fontWeight: FontWeight.w600),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 6),
            Icon(
              LucideIcons.chevron_right,
              size: 16,
              color: AppColors.mutedForeground,
            ),
          ],
        ],
      ),
    );
    if (onTap == null) return ligne;
    return InkWell(onTap: onTap, child: ligne);
  }
}

class _PaymentLine extends StatelessWidget {
  final String title;
  final String date;
  final String amount;

  const _PaymentLine({
    required this.title,
    required this.date,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyMedium(color: AppColors.foreground)
                      .copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  date,
                  style: AppTypography.caption(color: AppColors.mutedForeground),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: AppTypography.bodyMedium(color: AppColors.positive)
                .copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
