import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/design_system.dart';
import '../../auth/data/auth_repository.dart';
import '../../biens/data/biens_repository.dart';
import '../../biens/data/biens_results.dart';
import '../../biens/models/immeuble.dart';
import '../../biens/models/lot.dart';
import '../../locataires/data/locataire_results.dart';
import '../../locataires/data/owners_repository.dart';
import '../../locataires/models/owner.dart';
import '../data/finances_repository.dart';
import '../data/finances_results.dart';
import '../models/depense.dart';
import '../models/depense_validation.dart';
import '../models/finance_format.dart';

/// Rattachement d'une dépense : un immeuble (lot facultatif), ou un
/// propriétaire pour une dépense générale — voir `expenseRoutes.ts`
/// (`POST /expenses`) : l'un des deux est obligatoire, sinon 422.
enum _Rattachement { immeuble, proprietaire }

/// Formulaire d'enregistrement d'une dépense (`POST /api/expenses`, voir
/// `expenseRoutes.ts`) — phase 4.5, étape 3/3.
///
/// Récapitulatif obligatoire avant l'envoi (verrou anti-double-appui, même
/// pattern qu'`EncaisserScreen`, T-044). Pas d'étapes distinctes ici (tous
/// les champs sont réels d'emblée, contrairement à l'encaissement où le
/// contexte — locataire/bail/échéance — doit d'abord être choisi) : un seul
/// écran de formulaire.
class DepenseScreen extends StatefulWidget {
  const DepenseScreen({super.key, this.maintenant});

  /// Horloge injectable (tests) : date du jour par défaut et borne « jamais
  /// dans le futur ». `DateTime.now` sinon.
  final DateTime Function()? maintenant;

  @override
  State<DepenseScreen> createState() => _DepenseScreenState();
}

class _DepenseScreenState extends State<DepenseScreen>
    with VerrouEnvoi {
  late final DateTime Function() _now = widget.maintenant ?? DateTime.now;
  late final OwnersRepository _ownersRepository;
  final ImagePicker _picker = ImagePicker();

  bool _loading = true;
  String? _erreurChargement;

  List<Immeuble> _immeubles = [];
  List<Lot> _lots = [];
  List<CategorieDepense> _categories = [];
  List<Owner> _owners = [];

  // Formulaire.
  String? _categorieChoisie;
  final _montantController = TextEditingController();
  late DateTime _date;
  final _dateController = TextEditingController();
  final _intituleController = TextEditingController();
  final _fournisseurController = TextEditingController();
  File? _justificatif;

  _Rattachement? _typeRattachement;
  Immeuble? _immeubleChoisi;
  Lot? _lotChoisi;
  Owner? _proprietaireChoisi;

  String? _erreurCategorie;
  String? _erreurMontant;
  String? _erreurDate;
  String? _erreurRattachement;
  String? _erreurJustificatif;

  /// Message affiché après un échec d'envoi (400/422/erreur générique/
  /// réseau) — pas un champ précis, en bas du formulaire.
  String? _erreurEnvoi;

  @override
  void initState() {
    super.initState();
    _date = _dateDuJour();
    _dateController.text = formatDateLongue(_date);
    _ownersRepository = OwnersRepository(
      apiClient: AuthRepository.instance.apiClient,
    );
    _chargerReferentiel();
  }

  @override
  void dispose() {
    _montantController.dispose();
    _dateController.dispose();
    _intituleController.dispose();
    _fournisseurController.dispose();
    super.dispose();
  }

  DateTime _dateDuJour() {
    final n = _now();
    return DateTime(n.year, n.month, n.day);
  }

  // ── Chargement du référentiel (immeubles, lots, catégories, propriétaires) ──

  Future<void> _chargerReferentiel() async {
    setState(() {
      _loading = true;
      _erreurChargement = null;
    });
    final resultats = await (
      BiensRepository.instance.listImmeubles(),
      BiensRepository.instance.listLots(),
      FinancesRepository.instance.listCategoriesDepense(),
      _ownersRepository.list(),
    ).wait;
    if (!mounted) return;
    final (immeublesResult, lotsResult, categoriesResult, ownersResult) = resultats;
    final erreur = switch ((immeublesResult, lotsResult, categoriesResult, ownersResult)) {
      (ImmeublesListFailure(:final message), _, _, _) => message,
      (_, LotsListFailure(:final message), _, _) => message,
      (_, _, CategoriesDepenseFailure(:final message), _) => message,
      (_, _, _, OwnersListFailure(:final message)) => message,
      _ => null,
    };
    setState(() {
      _loading = false;
      _erreurChargement = erreur;
      if (erreur == null) {
        _immeubles = (immeublesResult as ImmeublesListSuccess).items;
        _lots = (lotsResult as LotsListSuccess).items;
        _categories = (categoriesResult as CategoriesDepenseSuccess).items;
        _owners = (ownersResult as OwnersListSuccess).owners;
      }
    });
  }

  // ── Rattachement ──────────────────────────────────────────────────────

  List<Lot> get _lotsDeLImmeuble {
    final id = _immeubleChoisi?.id;
    if (id == null) return const [];
    return _lots.where((l) => l.buildingId == id).toList();
  }

  void _onChoisirTypeRattachement(_Rattachement type) {
    setState(() {
      _typeRattachement = type;
      _erreurRattachement = null;
    });
  }

  // ── Justificatif ──────────────────────────────────────────────────────

  Future<void> _choisirJustificatif() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const _SourcePhotoSheet(),
    );
    if (source == null || !mounted) return;

    final XFile? picked;
    try {
      picked = await _picker.pickImage(source: source, imageQuality: 85);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _erreurJustificatif = source == ImageSource.camera
            ? "Impossible d'ouvrir l'appareil photo."
            : "Impossible d'ouvrir la galerie.";
      });
      return;
    }
    if (picked == null || !mounted) return;

    final file = File(picked.path);
    final octets = await file.length();
    if (!mounted) return;
    final erreurTaille = validerTailleJustificatif(octets);
    setState(() {
      if (erreurTaille != null) {
        _erreurJustificatif = erreurTaille;
      } else {
        _justificatif = file;
        _erreurJustificatif = null;
      }
    });
  }

  void _supprimerJustificatif() {
    setState(() {
      _justificatif = null;
      _erreurJustificatif = null;
    });
  }

  // ── Date ──────────────────────────────────────────────────────────────

  Future<void> _choisirDate() async {
    final premiere = DateTime(_now().year - 3);
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: premiere,
      lastDate: _dateDuJour(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            onSurface: AppColors.foreground,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _date = picked;
        _dateController.text = formatDateLongue(_date);
        _erreurDate = null;
      });
    }
  }

  // ── Validation & envoi ────────────────────────────────────────────────

  double? _montantSaisi() {
    final texte = _montantController.text.trim().replaceAll(' ', '');
    if (texte.isEmpty) return null;
    return double.tryParse(texte);
  }

  void _onEnvoyer() {
    final erreurCategorie = _categorieChoisie == null
        ? 'Choisissez une catégorie.'
        : null;
    final erreurMontant = validerMontantDepense(_montantSaisi());
    final erreurDate = validerDateDepense(_date, _dateDuJour());
    final erreurRattachement = switch (_typeRattachement) {
      null => 'Choisissez un immeuble ou un propriétaire.',
      _Rattachement.immeuble =>
        _immeubleChoisi == null ? 'Choisissez un immeuble.' : null,
      _Rattachement.proprietaire =>
        _proprietaireChoisi == null ? 'Choisissez un propriétaire.' : null,
    };
    setState(() {
      _erreurCategorie = erreurCategorie;
      _erreurMontant = erreurMontant;
      _erreurDate = erreurDate;
      _erreurRattachement = erreurRattachement;
    });
    if (erreurCategorie != null ||
        erreurMontant != null ||
        erreurDate != null ||
        erreurRattachement != null) {
      return;
    }
    _ouvrirRecapitulatif();
  }

  void _ouvrirRecapitulatif() {
    setState(() => _erreurEnvoi = null);
    afficherRecapitulatifEnvoi(
      context,
      envoiEnCours: envoiEnCours,
      titre: 'Confirmer la dépense',
      contenu: () {
        final intitule = _intituleController.text.trim();
        final fournisseur = _fournisseurController.text.trim();
        return [
          AppRecapRow(label: 'Catégorie', value: _categorieChoisie!),
          AppRecapRow(label: 'Montant', value: formatMontant(_montantSaisi() ?? 0)),
          AppRecapRow(label: 'Date', value: formatDateLongue(_date)),
          if (intitule.isNotEmpty) AppRecapRow(label: 'Intitulé', value: intitule),
          if (fournisseur.isNotEmpty) AppRecapRow(label: 'Fournisseur', value: fournisseur),
          AppRecapRow(label: 'Rattachement', value: _rattachementLibelle),
          AppRecapRow(
            label: 'Justificatif',
            value: _justificatif != null ? 'Joint' : 'Aucun',
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warningSoft,
              borderRadius: AppRadius.borderMd,
            ),
            child: Text(
              'Cette dépense ne pourra être corrigée ou supprimée que depuis '
              "l'espace web.",
              style: AppTypography.bodySmall(color: AppColors.warning),
            ),
          ),
        ];
      },
      onConfirmer: _confirmerEnvoi,
    );
  }

  String get _rattachementLibelle {
    if (_typeRattachement == _Rattachement.immeuble) {
      final immeuble = _immeubleChoisi;
      if (immeuble == null) return '—';
      final lot = _lotChoisi;
      return lot == null ? immeuble.nom : '${immeuble.nom} · ${lot.reference}';
    }
    return _proprietaireChoisi?.displayName ?? '—';
  }

  Future<void> _confirmerEnvoi(BuildContext sheetContext) async {
    if (!prendreVerrouEnvoi()) return; // garde anti-double-appui

    final intitule = _intituleController.text.trim();
    final fournisseur = _fournisseurController.text.trim();
    final result = await FinancesRepository.instance.creerDepense(
      categorie: _categorieChoisie!,
      montant: _montantSaisi() ?? 0,
      date: _date,
      intitule: intitule.isEmpty ? null : intitule,
      fournisseur: fournisseur.isEmpty ? null : fournisseur,
      buildingId: _typeRattachement == _Rattachement.immeuble
          ? _immeubleChoisi?.id
          : null,
      lotId: _typeRattachement == _Rattachement.immeuble
          ? _lotChoisi?.id
          : null,
      ownerId: _typeRattachement == _Rattachement.proprietaire
          ? _proprietaireChoisi?.id
          : null,
      justificatif: _justificatif,
    );
    if (!mounted) return;
    libererVerrouEnvoi();
    if (!sheetContext.mounted) return; // feuille déjà fermée entre-temps

    switch (result) {
      case CreerDepenseSuccess():
        Navigator.of(sheetContext).pop();
        _apresSucces();
      case CreerDepenseValidationFailed(:final message):
        // 400/422 : reste sur le formulaire, rien n'est perdu (contrôleurs
        // et justificatif intacts).
        Navigator.of(sheetContext).pop();
        setState(() => _erreurEnvoi = message);
      case CreerDepenseFichierRefuse(:final message):
        Navigator.of(sheetContext).pop();
        setState(() {
          _erreurJustificatif = message;
          _erreurEnvoi = message;
        });
      case CreerDepenseNetworkError():
        // Jamais de nouvel envoi automatique : l'utilisateur garde son
        // formulaire intact et vérifie l'état réel (onglet Finances) avant
        // toute nouvelle tentative — pas de liste à recharger ici,
        // contrairement à l'échéancier d'`EncaisserScreen`.
        Navigator.of(sheetContext).pop();
        setState(
          () => _erreurEnvoi =
              "Une erreur réseau est survenue. La dépense a peut-être tout "
              'de même été enregistrée : vérifiez dans Finances avant de '
              'réessayer.',
        );
      case CreerDepenseFailure(:final message):
        Navigator.of(sheetContext).pop();
        setState(() => _erreurEnvoi = message);
    }
  }

  // `true` à la fermeture (voir `afficherSuccesEnvoi`) : l'écran d'origine
  // recharge de toute façon dans tous les cas (voir call sites).
  Future<void> _apresSucces() => afficherSuccesEnvoi(
    context,
    titre: 'Dépense enregistrée',
    actions: (_, terminer) => [
      AppButton.primary(label: 'Retour aux finances', onPressed: terminer),
    ],
  );

  // ── Rendu ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(onBack: () => Navigator.of(context).pop()),
            Expanded(child: _corps),
          ],
        ),
      ),
    );
  }

  Widget get _corps {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_erreurChargement != null) {
      return _Erreur(message: _erreurChargement!, onRetry: _chargerReferentiel);
    }
    return _buildFormulaire();
  }

  Widget _buildFormulaire() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        // Catégorie.
        Text(
          'CATÉGORIE DE DÉPENSE',
          style: AppTypography.labelUppercase(
            color: AppColors.mutedForeground,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 10),
        if (_categories.isEmpty)
          Text(
            'Aucune catégorie disponible.',
            style: AppTypography.bodySmall(color: AppColors.mutedForeground),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categories
                .map(
                  (cat) => _Chip(
                    label: cat.nom,
                    selected: _categorieChoisie == cat.nom,
                    onTap: () => setState(() {
                      _categorieChoisie = cat.nom;
                      _erreurCategorie = null;
                    }),
                  ),
                )
                .toList(),
          ),
        if (_erreurCategorie != null) ...[
          const SizedBox(height: 6),
          Text(
            _erreurCategorie!,
            style: AppTypography.bodySmall(color: AppColors.error),
          ),
        ],
        const SizedBox(height: 20),

        // Montant.
        Text(
          'MONTANT DE LA DÉPENSE (FCFA)',
          style: AppTypography.labelUppercase(
            color: AppColors.mutedForeground,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 6),
        AppTextField(
          controller: _montantController,
          keyboardType: const TextInputType.numberWithOptions(),
          hintText: '45000',
          errorText: _erreurMontant,
          prefixIcon: Icon(
            LucideIcons.coins,
            size: 16,
            color: AppColors.mutedForeground,
          ),
        ),
        const SizedBox(height: 16),

        // Date.
        Text(
          'DATE DE LA DÉPENSE',
          style: AppTypography.labelUppercase(
            color: AppColors.mutedForeground,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 6),
        AppTextField(
          readOnly: true,
          onTap: _choisirDate,
          controller: _dateController,
          errorText: _erreurDate,
          suffixIcon: Icon(
            LucideIcons.calendar,
            size: 16,
            color: AppColors.mutedForeground,
          ),
        ),
        const SizedBox(height: 16),

        // Intitulé.
        Text(
          'INTITULÉ (FACULTATIF)',
          style: AppTypography.labelUppercase(
            color: AppColors.mutedForeground,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 6),
        AppTextField(
          controller: _intituleController,
          hintText: 'Ex: Remplacement chauffe-eau / Gardiennage Mars',
          prefixIcon: Icon(
            LucideIcons.file_pen,
            size: 16,
            color: AppColors.mutedForeground,
          ),
        ),
        const SizedBox(height: 16),

        // Fournisseur.
        Text(
          'FOURNISSEUR (FACULTATIF)',
          style: AppTypography.labelUppercase(
            color: AppColors.mutedForeground,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 6),
        AppTextField(
          controller: _fournisseurController,
          hintText: 'Ex: ETS Plomberie Moderne / M. Diallo',
          prefixIcon: Icon(
            LucideIcons.user,
            size: 16,
            color: AppColors.mutedForeground,
          ),
        ),
        const SizedBox(height: 20),

        // Rattachement.
        Text(
          'RATTACHEMENT',
          style: AppTypography.labelUppercase(
            color: AppColors.mutedForeground,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _ToggleOption(
                icon: LucideIcons.building,
                label: 'Immeuble',
                selected: _typeRattachement == _Rattachement.immeuble,
                onTap: () => _onChoisirTypeRattachement(_Rattachement.immeuble),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ToggleOption(
                icon: LucideIcons.user,
                label: 'Propriétaire',
                selected: _typeRattachement == _Rattachement.proprietaire,
                onTap: () =>
                    _onChoisirTypeRattachement(_Rattachement.proprietaire),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_typeRattachement == _Rattachement.immeuble) ...[
          AppDropdown<Immeuble>(
            value: _immeubleChoisi,
            hintText: 'Choisir un immeuble',
            items: _immeubles
                .map((i) => AppDropdownItem(label: i.nom, value: i))
                .toList(),
            onChanged: (val) => setState(() {
              _immeubleChoisi = val;
              _lotChoisi = null;
              _erreurRattachement = null;
            }),
          ),
          if (_immeubleChoisi != null) ...[
            const SizedBox(height: 10),
            AppDropdown<Lot?>(
              value: _lotChoisi,
              hintText: 'Lot (optionnel)',
              items: [
                const AppDropdownItem<Lot?>(
                  label: "Dépense générale de l'immeuble",
                  value: null,
                ),
                ..._lotsDeLImmeuble.map(
                  (l) => AppDropdownItem<Lot?>(label: l.reference, value: l),
                ),
              ],
              onChanged: (val) => setState(() => _lotChoisi = val),
            ),
          ],
        ] else if (_typeRattachement == _Rattachement.proprietaire) ...[
          AppDropdown<Owner>(
            value: _proprietaireChoisi,
            hintText: 'Choisir un propriétaire',
            items: _owners
                .map((o) => AppDropdownItem(label: o.displayName, value: o))
                .toList(),
            onChanged: (val) => setState(() {
              _proprietaireChoisi = val;
              _erreurRattachement = null;
            }),
          ),
        ],
        if (_erreurRattachement != null) ...[
          const SizedBox(height: 6),
          Text(
            _erreurRattachement!,
            style: AppTypography.bodySmall(color: AppColors.error),
          ),
        ],
        const SizedBox(height: 20),

        // Justificatif.
        Text(
          'JUSTIFICATIF (FACULTATIF)',
          style: AppTypography.labelUppercase(
            color: AppColors.mutedForeground,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 8),
        _justificatif != null
            ? _JustificatifApercu(
                fichier: _justificatif!,
                onSupprimer: _supprimerJustificatif,
              )
            : _JustificatifVide(onTap: _choisirJustificatif),
        if (_erreurJustificatif != null) ...[
          const SizedBox(height: 6),
          Text(
            _erreurJustificatif!,
            style: AppTypography.bodySmall(color: AppColors.error),
          ),
        ],
        const SizedBox(height: 24),

        if (_erreurEnvoi != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.warningSoft,
              borderRadius: AppRadius.borderMd,
            ),
            child: Text(
              _erreurEnvoi!,
              style: AppTypography.bodySmall(color: AppColors.warning),
            ),
          ),
        ],

        // Pas d'icône (contrairement à `EncaisserScreen`) : avec ce libellé
        // plus long, icône + texte dépassait la largeur du bouton (débordement
        // constaté en test, 390px de large).
        AppButton.primary(
          label: 'Enregistrer la dépense',
          onPressed: _onEnvoyer,
        ),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: Icon(LucideIcons.arrow_left, color: AppColors.foreground),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Enregistrer une dépense',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.titleScreen(fontSize: 22),
            ),
          ),
        ],
      ),
    );
  }
}

class _Erreur extends StatelessWidget {
  const _Erreur({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall(color: AppColors.mutedForeground),
          ),
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: const Text('Réessayer')),
        ],
      ),
    ),
  );
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      backgroundColor: AppColors.card,
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: selected ? Colors.white : AppColors.foreground,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        fontSize: 12.5,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: selected ? AppColors.primary : AppColors.border),
      ),
      showCheckmark: false,
    );
  }
}

class _ToggleOption extends StatelessWidget {
  const _ToggleOption({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.card,
      borderRadius: AppRadius.borderMd,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.borderMd,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: AppRadius.borderMd,
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: selected ? AppColors.primary : AppColors.mutedForeground,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: AppTypography.bodySmall(
                  color: selected ? AppColors.primary : AppColors.foreground,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _JustificatifVide extends StatelessWidget {
  const _JustificatifVide({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.camera,
                color: AppColors.mutedForeground,
                size: 26,
              ),
              const SizedBox(height: 6),
              Text(
                'Prendre une photo ou importer un reçu',
                style: AppTypography.bodySmall(
                  color: AppColors.mutedForeground,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _JustificatifApercu extends StatelessWidget {
  const _JustificatifApercu({required this.fichier, required this.onSupprimer});
  final File fichier;
  final VoidCallback onSupprimer;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.file(
            fichier,
            height: 140,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              height: 140,
              color: AppColors.muted,
              child: Icon(
                LucideIcons.image_off,
                size: 26,
                color: AppColors.mutedForeground,
              ),
            ),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: onSupprimer,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.x, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

class _SourcePhotoSheet extends StatelessWidget {
  const _SourcePhotoSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: AppRadius.borderFull,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Justificatif', style: AppTypography.titleSection()),
          const SizedBox(height: 14),
          _SourceOption(
            icon: LucideIcons.camera,
            label: 'Prendre une photo',
            onTap: () => Navigator.of(context).pop(ImageSource.camera),
          ),
          const SizedBox(height: 8),
          _SourceOption(
            icon: LucideIcons.image,
            label: 'Choisir depuis la galerie',
            onTap: () => Navigator.of(context).pop(ImageSource.gallery),
          ),
        ],
      ),
    );
  }
}

class _SourceOption extends StatelessWidget {
  const _SourceOption({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      borderRadius: AppRadius.borderMd,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.borderMd,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
