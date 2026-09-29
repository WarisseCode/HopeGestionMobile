import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_config.dart';
import '../../../core/design_system.dart';
import '../data/finances_repository.dart';
import '../data/finances_results.dart';
import '../models/depense.dart';
import '../models/finance_format.dart';
import '../models/mouvement.dart';
import '../models/paiement.dart';

/// Fiche d'un mouvement : paiement (encaissement) ou dépense, à partir des
/// données réelles de `GET /finances` / `GET /expenses`.
///
/// Deux points d'entrée :
/// - la liste Finances, qui a déjà le [Mouvement] ;
/// - le tableau de bord, qui ne connaît que l'`id` d'un paiement récent
///   ([TransactionDetailScreen.paiement]) : le paiement est alors chargé via
///   [FinancesRepository.findPaiement].
class TransactionDetailScreen extends StatefulWidget {
  const TransactionDetailScreen({super.key, required Mouvement this.mouvement})
    : paiementId = null;

  const TransactionDetailScreen.paiement({
    super.key,
    required int this.paiementId,
  }) : mouvement = null;

  final Mouvement? mouvement;
  final int? paiementId;

  @override
  State<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  Mouvement? _mouvement;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _mouvement = widget.mouvement;
    if (_mouvement == null) _load();
  }

  @override
  void didUpdateWidget(TransactionDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.mouvement != oldWidget.mouvement ||
        widget.paiementId != oldWidget.paiementId) {
      _mouvement = widget.mouvement;
      if (_mouvement == null) _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await FinancesRepository.instance.findPaiement(
      widget.paiementId!,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      switch (result) {
        case PaiementTrouve(:final paiement):
          _mouvement = MouvementPaiement(paiement);
        case PaiementIntrouvable():
          _error = 'Ce paiement est introuvable.';
        case PaiementFailure(:final message):
          _error = message;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final mouvement = _mouvement;
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
                      mouvement is MouvementDepense
                          ? 'Détail de la dépense'
                          : 'Détail du paiement',
                      style: AppTypography.titleScreen(fontSize: 20),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: switch (mouvement) {
                MouvementPaiement(:final paiement) => _FichePaiement(paiement),
                MouvementDepense(:final depense) => _FicheDepense(depense),
                null when _loading => const Center(
                  child: CircularProgressIndicator(),
                ),
                null => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _error ?? '',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodySmall(
                            color: AppColors.mutedForeground,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: _load,
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  ),
                ),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _FichePaiement extends StatelessWidget {
  const _FichePaiement(this.paiement);

  final Paiement paiement;

  @override
  Widget build(BuildContext context) {
    final quittance = paiement.quittanceUrl;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        _CarteMontant(
          estEntree: true,
          montant: paiement.montant,
          sousTitre: 'Encaissement · ${libelleTypePaiement(paiement.type)}',
          badge: switch (paiement.statut) {
            'valide' => const AppBadge.positive('Validé'),
            'annule' => const AppBadge.danger('Annulé'),
            _ => AppBadge.warning(libelleStatutPaiement(paiement.statut)),
          },
        ),
        const SizedBox(height: 20),
        _Informations(
          titre: 'INFORMATIONS SUR LE PAIEMENT',
          lignes: [
            ('Locataire', paiement.locataireNomComplet ?? '—'),
            ('Bail', paiement.referenceBail ?? '—'),
            ('Montant', formatMontant(paiement.montant)),
            ('Date du paiement', formatDateLongue(paiement.date)),
            ('Mode de paiement', libelleModePaiement(paiement.modePaiement)),
            ('Référence', _ouTiret(paiement.reference)),
            if (_nonVide(paiement.description))
              ('Description', paiement.description!.trim()),
            if (_nonVide(paiement.proprietaireNom))
              ('Propriétaire', paiement.proprietaireNom!.trim()),
          ],
        ),
        if (quittance != null && quittance.isNotEmpty) ...[
          const SizedBox(height: 20),
          _LienFichier(
            icone: LucideIcons.file_text,
            libelle: 'Quittance (PDF)',
            url: AppConfig.resolveFileUrl(quittance),
          ),
        ],
      ],
    );
  }
}

class _FicheDepense extends StatelessWidget {
  const _FicheDepense(this.depense);

  final Depense depense;

  static final _image = RegExp(r'\.(jpe?g|png|webp|gif)$', caseSensitive: false);

  @override
  Widget build(BuildContext context) {
    final justificatif = depense.justificatifUrl;
    final url = justificatif == null || justificatif.isEmpty
        ? null
        : AppConfig.resolveFileUrl(justificatif);
    final estImage = url != null && _image.hasMatch(Uri.parse(url).path);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        _CarteMontant(
          estEntree: false,
          montant: depense.montant,
          sousTitre: 'Dépense · ${depense.categorie}',
        ),
        const SizedBox(height: 20),
        _Informations(
          titre: 'INFORMATIONS SUR LA DÉPENSE',
          lignes: [
            ('Catégorie', depense.categorie),
            ('Intitulé', depense.intitule),
            ('Immeuble', _ouTiret(depense.immeubleNom)),
            ('Lot', _ouTiret(depense.lotReference)),
            ('Fournisseur', _ouTiret(depense.fournisseur)),
            ('Montant', formatMontant(depense.montant)),
            ('Date', formatDateLongue(depense.date)),
          ],
        ),
        const SizedBox(height: 20),
        if (url == null)
          Text(
            'Aucun justificatif joint.',
            style: AppTypography.bodySmall(color: AppColors.mutedForeground),
          )
        else if (estImage)
          _JustificatifImage(url: url)
        else
          _LienFichier(
            icone: LucideIcons.receipt,
            libelle: 'Justificatif',
            url: url,
          ),
      ],
    );
  }
}

bool _nonVide(String? s) => s != null && s.trim().isNotEmpty;
String _ouTiret(String? s) => _nonVide(s) ? s!.trim() : '—';

class _CarteMontant extends StatelessWidget {
  const _CarteMontant({
    required this.estEntree,
    required this.montant,
    required this.sousTitre,
    this.badge,
  });

  final bool estEntree;
  final double montant;
  final String sousTitre;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(24),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: estEntree
                    ? AppColors.positiveSoft
                    : AppColors.warningSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(
                estEntree
                    ? LucideIcons.arrow_down_left
                    : LucideIcons.arrow_up_right,
                color: estEntree ? AppColors.positive : AppColors.warning,
                size: 26,
              ),
            ),
            const SizedBox(height: 12),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                formatMontantSigne(estEntree ? montant : -montant),
                style: AppTypography.titleScreen(
                  fontSize: 28,
                  color: estEntree ? AppColors.positive : AppColors.foreground,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              sousTitre,
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall(color: AppColors.mutedForeground),
            ),
            if (badge != null) ...[const SizedBox(height: 12), badge!],
          ],
        ),
      ),
    );
  }
}

class _Informations extends StatelessWidget {
  const _Informations({required this.titre, required this.lignes});

  final String titre;
  final List<(String, String)> lignes;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titre,
            style: AppTypography.labelUppercase(
              color: AppColors.mutedForeground,
              fontSize: 10.5,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < lignes.length; i++) ...[
            if (i > 0) Divider(color: AppColors.border, height: 1),
            _TxRow(label: lignes[i].$1, value: lignes[i].$2),
          ],
        ],
      ),
    );
  }
}

class _TxRow extends StatelessWidget {
  final String label;
  final String value;

  const _TxRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.bodySmall(color: AppColors.mutedForeground),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
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

/// Fichier non affichable dans l'app (PDF…) : ouvert dans l'application
/// externe associée (lecteur PDF, navigateur…). Si l'ouverture échoue —
/// aucune application compatible, ou refus de la plateforme — solution de
/// repli : le lien est copié dans le presse-papiers, avec un message clair.
class _LienFichier extends StatelessWidget {
  const _LienFichier({
    required this.icone,
    required this.libelle,
    required this.url,
  });

  final IconData icone;
  final String libelle;
  final String url;

  Future<void> _ouvrir(BuildContext context) async {
    var ouvert = false;
    try {
      ouvert = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {
      ouvert = false;
    }
    if (ouvert || !context.mounted) return;

    // Solution de repli : copie du lien, avec un message clair sur la raison.
    await Clipboard.setData(ClipboardData(text: url));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Impossible d'ouvrir ce fichier : le lien a été copié "
          'dans le presse-papiers',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icone, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  libelle,
                  style: AppTypography.body(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  url,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption(),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _ouvrir(context),
            child: const Text('Ouvrir'),
          ),
        ],
      ),
    );
  }
}

/// Justificatif image : aperçu dans la fiche, plein écran zoomable au tap.
class _JustificatifImage extends StatelessWidget {
  const _JustificatifImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'JUSTIFICATIF',
          style: AppTypography.labelUppercase(
            color: AppColors.mutedForeground,
            fontSize: 10.5,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => Scaffold(
                backgroundColor: Colors.black,
                appBar: AppBar(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  title: const Text('Justificatif'),
                ),
                body: Center(
                  child: InteractiveViewer(child: Image.network(url)),
                ),
              ),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              url,
              height: 220,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                height: 120,
                color: AppColors.muted,
                alignment: Alignment.center,
                child: Icon(
                  LucideIcons.image_off,
                  color: AppColors.mutedForeground,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
