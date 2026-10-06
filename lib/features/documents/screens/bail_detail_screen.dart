import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../core/design_system.dart';
import '../../finances/models/echeance.dart';
import '../../finances/models/finance_format.dart';
import '../data/baux_repository.dart';
import '../data/baux_results.dart';
import '../models/bail_detail.dart';

/// Fiche d'un bail en **lecture seule** — `GET /api/locations/:id`
/// (bail + échéancier en un seul appel, échéancier filtré par
/// `scopeByOwner` côté serveur). Ni résiliation, ni renouvellement, ni
/// signature ici (hors périmètre).
class BailDetailScreen extends StatefulWidget {
  const BailDetailScreen({super.key, required this.bailId, this.maintenant});

  final int bailId;

  /// Horloge injectable (tests) : calcul de l'état « en retard ».
  final DateTime Function()? maintenant;

  @override
  State<BailDetailScreen> createState() => _BailDetailScreenState();
}

class _BailDetailScreenState extends State<BailDetailScreen> {
  bool _loading = true;
  BailDetail? _bail;
  String? _errorTitle;
  String? _errorMessage;
  bool _retryable = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// [rafraichir] : tirer-pour-actualiser avec une fiche déjà affichée — pas
  /// d'écran de chargement ; une erreur réseau garde la fiche et s'affiche
  /// en SnackBar, un 404/403 bascule sur l'écran d'erreur (le bail n'est
  /// plus accessible, l'ancienne fiche serait trompeuse).
  Future<void> _load({bool rafraichir = false}) async {
    final silencieux = rafraichir && _bail != null;
    if (!silencieux) {
      setState(() {
        _loading = true;
        _errorTitle = null;
        _errorMessage = null;
      });
    }
    final result = await BauxRepository.instance.getBail(widget.bailId);
    if (!mounted) return;
    switch (result) {
      case BailDetailSuccess(:final bail):
        setState(() {
          _bail = bail;
          _errorTitle = null;
          _errorMessage = null;
          _loading = false;
        });
      case BailDetailIntrouvable():
        _afficherErreur(
          'Bail introuvable',
          'Ce bail n\'existe pas ou n\'est pas rattaché à un propriétaire '
              'que vous gérez.',
          retryable: false,
        );
      case BailDetailAccesRefuse():
        _afficherErreur(
          'Accès refusé',
          'Votre compte n\'a pas l\'autorisation de consulter les baux.',
          retryable: false,
        );
      case BailDetailNetworkError(:final message):
        if (silencieux) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Actualisation impossible : $message'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
        _afficherErreur('Connexion impossible', message, retryable: true);
      case BailDetailFailure(:final message):
        if (silencieux) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Actualisation impossible : $message'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
        _afficherErreur(
          'Impossible de charger ce bail',
          message,
          retryable: true,
        );
    }
  }

  void _afficherErreur(
    String titre,
    String message, {
    required bool retryable,
  }) {
    setState(() {
      _bail = null;
      _errorTitle = titre;
      _errorMessage = message;
      _retryable = retryable;
      _loading = false;
    });
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

    final bail = _bail;
    if (_errorTitle != null || bail == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              _topBar(context, ''),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _errorTitle ?? 'Impossible de charger ce bail',
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
                        if (_retryable) ...[
                          const SizedBox(height: 20),
                          AppButton.primary(
                            label: 'Réessayer',
                            onPressed: _load,
                            isFullWidth: false,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final maintenant = widget.maintenant?.call() ?? DateTime.now();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _topBar(context, 'Bail'),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () => _load(rafraichir: true),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                  children: [
                    _enTete(bail),
                    const SizedBox(height: 16),
                    _Carte(
                      titre: 'LOCATAIRE',
                      lignes: [
                        ('Nom', _ouNonRenseigne(bail.locataireNomComplet)),
                        ('Téléphone', _ouNonRenseigne(bail.locataireTelephone)),
                        ('Email', _ouNonRenseigne(bail.locataireEmail)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _Carte(
                      titre: 'LOGEMENT',
                      lignes: [
                        ('Lot', _ouNonRenseigne(bail.refLot)),
                        ('Type', _ouNonRenseigne(_majuscule(bail.lotType))),
                        ('Immeuble', _ouNonRenseigne(bail.immeubleNom)),
                        ('Adresse', _ouNonRenseigne(bail.immeubleAdresse)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _Carte(
                      titre: 'PROPRIÉTAIRE',
                      lignes: [('Nom', _ouNonRenseigne(bail.proprietaireNom))],
                    ),
                    const SizedBox(height: 16),
                    _Carte(
                      titre: 'CONDITIONS FINANCIÈRES',
                      lignes: [
                        ('Loyer mensuel', _montant(bail.loyerMensuel)),
                        (
                          'Charges mensuelles',
                          _montant(bail.chargesMensuelles),
                        ),
                        ('Caution', _montant(bail.caution)),
                        ('Avance', _avance(bail.avanceMois)),
                        (
                          'Jour d\'échéance',
                          bail.jourEcheance == null
                              ? 'Non renseigné'
                              : 'Le ${bail.jourEcheance} du mois',
                        ),
                        ('Début', _date(bail.dateDebut)),
                        ('Fin', _date(bail.dateFin)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'ÉCHÉANCIER (${bail.echeancier.length})',
                      style: AppTypography.labelUppercase(
                        color: AppColors.mutedForeground,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (bail.echeancier.isEmpty)
                      _echeancierVide()
                    else
                      for (final e in bail.echeancier) ...[
                        _EcheanceLigne(echeance: e, maintenant: maintenant),
                        const SizedBox(height: 10),
                      ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context, String title) {
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
              title,
              style: AppTypography.titleScreen(fontSize: 20),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _enTete(BailDetail bail) {
    final (libelle, type) = statutBail(bail.statut);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.positiveSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(LucideIcons.file_text, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bail.referenceBail ?? 'Bail n°${bail.id}',
                  style: AppTypography.titleScreen(fontSize: 18),
                ),
                const SizedBox(height: 6),
                AppBadge(label: libelle, type: type),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Échéancier vide : situation normale (un bail `classique` n'a aucune
  /// échéance générée à la création), présentée comme une information et
  /// non comme une erreur.
  Widget _echeancierVide() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.info, size: 18, color: AppColors.mutedForeground),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Aucune échéance pour le moment : c\'est normal pour un bail '
              'récent, les échéances sont générées au fil des mois.',
              style: AppTypography.bodySmall(color: AppColors.mutedForeground),
            ),
          ),
        ],
      ),
    );
  }
}

/// Libellé et couleur du statut d'un bail (`leases.statut`). Valeur inconnue
/// affichée telle quelle, badge neutre.
(String, AppBadgeType) statutBail(String statut) {
  switch (statut) {
    case 'actif':
      return ('Actif', AppBadgeType.positive);
    case 'signe':
      return ('Signé', AppBadgeType.positive);
    case 'brouillon':
      return ('Brouillon', AppBadgeType.neutral);
    case 'en_attente':
      return ('En attente', AppBadgeType.warning);
    case 'resilie':
      return ('Résilié', AppBadgeType.danger);
    case 'termine':
      return ('Terminé', AppBadgeType.neutral);
    case 'expire':
      return ('Expiré', AppBadgeType.warning);
    case '':
      return ('—', AppBadgeType.neutral);
  }
  return (statut, AppBadgeType.neutral);
}

String _ouNonRenseigne(String? value) =>
    value == null || value.trim().isEmpty ? 'Non renseigné' : value.trim();

String? _majuscule(String? value) {
  if (value == null || value.isEmpty) return value;
  return value[0].toUpperCase() + value.substring(1);
}

String _montant(double? value) =>
    value == null ? 'Non renseigné' : formatMontant(value);

String _date(DateTime? value) =>
    value == null ? 'Non renseignée' : formatDateLongue(value);

/// Avance en **nombre de mois** (T-059), jamais convertie en FCFA ici.
String _avance(int? mois) => mois == null ? 'Non renseignée' : '$mois mois';

class _Carte extends StatelessWidget {
  const _Carte({required this.titre, required this.lignes});

  final String titre;
  final List<(String, String)> lignes;

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
            titre,
            style: AppTypography.labelUppercase(
              color: AppColors.mutedForeground,
              fontSize: 10.5,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < lignes.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 130,
                    child: Text(
                      lignes[i].$1,
                      style: AppTypography.bodySmall(
                        color: AppColors.mutedForeground,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      lignes[i].$2,
                      textAlign: TextAlign.right,
                      style: AppTypography.bodySmall(
                        color: AppColors.foreground,
                      ).copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            if (i < lignes.length - 1)
              Divider(color: AppColors.border, height: 1),
          ],
        ],
      ),
    );
  }
}

/// Même présentation que `_EcheanceRow` d'`EncaisserScreen` (mêmes libellés
/// et couleurs de badge), plus l'état « Payée » que cet écran n'affiche
/// jamais (il ne liste que les échéances à encaisser). Non cliquable :
/// fiche en lecture seule.
class _EcheanceLigne extends StatelessWidget {
  const _EcheanceLigne({required this.echeance, required this.maintenant});

  final Echeance echeance;
  final DateTime maintenant;

  @override
  Widget build(BuildContext context) {
    final etat = echeance.etat(maintenant: maintenant);
    final (label, type) = switch (etat) {
      EtatEcheance.payee => ('Payée', AppBadgeType.positive),
      EtatEcheance.enRetard => ('En retard', AppBadgeType.danger),
      EtatEcheance.acompte => ('Acompte', AppBadgeType.warning),
      EtatEcheance.aPayer => ('À payer', AppBadgeType.neutral),
    };
    final description = echeance.description?.trim();
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description != null && description.isNotEmpty
                      ? description
                      : 'Échéance #${echeance.id}',
                  style: AppTypography.body(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (echeance.dateEcheance != null)
                  Text(
                    formatDateLongue(echeance.dateEcheance!),
                    style: AppTypography.caption(
                      color: AppColors.mutedForeground,
                    ),
                  ),
                if (echeance.estAcompte)
                  Text(
                    'Versé ${formatMontant(echeance.montantPaye)} · '
                    'Reste ${formatMontant(echeance.resteDu)}',
                    style: AppTypography.caption(color: AppColors.warning),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatMontant(echeance.total),
                style: AppTypography.body(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              AppBadge(label: label, type: type),
            ],
          ),
        ],
      ),
    );
  }
}
