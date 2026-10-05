import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../core/design_system.dart';
import '../../../core/network/api_exception.dart';
import '../../biens/data/biens_repository.dart';
import '../../biens/data/biens_results.dart';
import '../../biens/models/lot.dart';
import '../../finances/models/finance_format.dart' show formatDateLongue;
import '../../locataires/data/locataire_results.dart';
import '../../locataires/data/locataires_repository.dart';
import '../../locataires/models/locataire.dart';
import '../data/baux_repository.dart';
import '../data/baux_results.dart';
import '../models/nouveau_bail.dart';

/// Étape courante du parcours. Le lot vient en premier : c'est lui qui
/// détermine le propriétaire (`owner_id`, obligatoire à l'envoi) et donc la
/// liste des locataires proposés.
enum _Etape { lot, locataire, formulaire }

/// Lot proposable : disponible et rattaché à un propriétaire (sans
/// `owner_id`, le bail serait créé orphelin — le web bloque aussi ce cas).
bool _lotProposable(Lot l) => l.statut == 'disponible' && l.ownerId != null;

/// Création d'un bail de location (`POST /api/locations`, HopeGestionV2
/// `leaseRoutes.ts`).
///
/// Parcours : Lot → Locataire (même propriétaire que le lot) → Formulaire →
/// récapitulatif (feuille de confirmation) → envoi unique. Ni PDF ni
/// échéancier générés ici.
class NouveauContratScreen extends StatefulWidget {
  const NouveauContratScreen({super.key, this.maintenant});

  /// Horloge injectable (tests) : date de début par défaut.
  final DateTime Function()? maintenant;

  @override
  State<NouveauContratScreen> createState() => _NouveauContratScreenState();
}

class _NouveauContratScreenState extends State<NouveauContratScreen> {
  late final DateTime Function() _now = widget.maintenant ?? DateTime.now;

  _Etape _etape = _Etape.lot;
  final List<_Etape> _historique = [];

  // Étape Lot.
  final _rechercheLotController = TextEditingController();
  bool _loadingLots = false;
  String? _erreurLots;

  /// Lots refusés par le serveur pendant cette session (400 « déjà une
  /// affectation active ») : masqués même si la liste les dit encore
  /// disponibles.
  final Set<int> _lotsRefuses = {};

  /// Bandeau affiché en haut de l'étape Lot (retour après lot refusé).
  String? _avisLot;

  // Étape Locataire.
  final _rechercheLocataireController = TextEditingController();
  bool _loadingLocataires = false;
  String? _erreurLocataires;

  // Sélection.
  Lot? _lot;
  Locataire? _locataire;

  // Étape Formulaire.
  late DateTime _dateDebut;
  final _dateDebutController = TextEditingController();
  final _dureeController = TextEditingController();
  final _loyerController = TextEditingController();
  final _cautionController = TextEditingController();
  final _chargesController = TextEditingController();
  final _avanceController = TextEditingController();
  final _jourEcheanceController = TextEditingController();
  final _conditionsController = TextEditingController();
  Map<String, String?> _erreurs = {};

  /// Message en haut du formulaire après un échec d'envoi.
  String? _avisFormulaire;

  /// Verrou d'envoi, posé de façon synchrone avant l'appel réseau : un
  /// double appui ne peut pas déclencher une deuxième requête (backend non
  /// transactionnel — deux baux pourraient être créés sur le même lot).
  final ValueNotifier<bool> _envoiEnCours = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    for (final c in [
      _rechercheLotController,
      _rechercheLocataireController,
      _dureeController,
      _loyerController,
      _avanceController,
      _conditionsController,
    ]) {
      c.addListener(_rafraichir);
    }
    _chargerLots();
    _chargerLocataires();
  }

  void _rafraichir() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    for (final c in [
      _rechercheLotController,
      _rechercheLocataireController,
      _dateDebutController,
      _dureeController,
      _loyerController,
      _cautionController,
      _chargesController,
      _avanceController,
      _jourEcheanceController,
      _conditionsController,
    ]) {
      c.dispose();
    }
    _envoiEnCours.dispose();
    super.dispose();
  }

  // ── Navigation ────────────────────────────────────────────────────────

  void _allerA(_Etape destination) {
    setState(() {
      _historique.add(_etape);
      _etape = destination;
    });
  }

  void _precedent() {
    if (_historique.isEmpty) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _etape = _historique.removeLast());
  }

  // ── Chargements ───────────────────────────────────────────────────────

  /// Toujours relancé à l'ouverture (le statut des lots doit être frais
  /// pour limiter le 400 « déjà une affectation active ») ; le chargeur
  /// n'est affiché que si aucun lot n'est encore en cache.
  Future<void> _chargerLots() async {
    setState(() {
      _loadingLots = BiensRepository.instance.lots.isEmpty;
      _erreurLots = null;
    });
    final result = await BiensRepository.instance.listLots();
    if (!mounted) return;
    setState(() {
      _loadingLots = false;
      _erreurLots = switch (result) {
        LotsListSuccess() => null,
        LotsListFailure(:final message) => message,
      };
    });
  }

  Future<void> _chargerLocataires() async {
    setState(() {
      _loadingLocataires = LocatairesRepository.instance.items.isEmpty;
      _erreurLocataires = null;
    });
    final result = await LocatairesRepository.instance.refresh();
    if (!mounted) return;
    setState(() {
      _loadingLocataires = false;
      _erreurLocataires = switch (result) {
        LocatairesListSuccess() => null,
        LocatairesListFailure(:final message) => message,
      };
    });
  }

  List<Lot> get _lotsDisponibles => BiensRepository.instance.lots
      .where(_lotProposable)
      .where((l) => !_lotsRefuses.contains(l.id))
      .toList();

  int get _lotsDisponiblesSansProprietaire => BiensRepository.instance.lots
      .where((l) => l.statut == 'disponible' && l.ownerId == null)
      .length;

  /// Tous les locataires non archivés du propriétaire du lot. Un locataire
  /// peut avoir plusieurs baux actifs : aucun filtre sur ses baux existants.
  List<Locataire> get _locatairesDuProprietaire {
    final ownerId = _lot?.ownerId;
    if (ownerId == null) return const [];
    return LocatairesRepository.instance.items
        .where((l) => l.ownerId == ownerId && l.statut != 'Archivé')
        .toList();
  }

  // ── Sélections ────────────────────────────────────────────────────────

  void _onSelectLot(Lot lot) {
    setState(() {
      _lot = lot;
      _locataire = null;
      _avisLot = null;
      _rechercheLocataireController.text = '';
      _initialiserFormulaire(lot);
    });
    _allerA(_Etape.locataire);
  }

  void _onSelectLocataire(Locataire l) {
    setState(() => _locataire = l);
    _allerA(_Etape.formulaire);
  }

  /// Pré-remplissage depuis la fiche du lot (loyer, caution, charges,
  /// avance en mois) ; durée 12 mois, échéance le 5, début aujourd'hui.
  void _initialiserFormulaire(Lot lot) {
    final maintenant = _now();
    _dateDebut = DateTime(maintenant.year, maintenant.month, maintenant.day);
    _dateDebutController.text = formatDateLongue(_dateDebut);
    _dureeController.text = '$dureeBailParDefautMois';
    _loyerController.text = lot.loyer != null ? '${lot.loyer!.round()}' : '';
    _cautionController.text = '${(lot.caution ?? 0).round()}';
    _chargesController.text = '${(lot.charges ?? 0).round()}';
    _avanceController.text = '${lot.avance < 0 ? 0 : lot.avance}';
    _jourEcheanceController.text = '$jourEcheanceParDefaut';
    _conditionsController.text = '';
    _erreurs = {};
    _avisFormulaire = null;
  }

  // ── Formulaire ────────────────────────────────────────────────────────

  static int? _entier(TextEditingController c) =>
      int.tryParse(c.text.trim().replaceAll(' ', ''));

  static double? _montant(TextEditingController c) {
    final texte = c.text.trim().replaceAll(' ', '');
    if (texte.isEmpty) return null;
    return double.tryParse(texte);
  }

  DateTime? get _dateFinCalculee {
    final duree = _entier(_dureeController);
    if (duree == null || duree < 1 || duree > 1200) return null;
    return calculerDateFinBail(_dateDebut, duree);
  }

  /// Aide visuelle « 2 mois = 370 000 FCFA », purement informative : le
  /// serveur reçoit l'avance en nombre de mois, pas ce montant.
  String? get _libelleAvanceCourant {
    final mois = _entier(_avanceController);
    final loyer = _montant(_loyerController);
    if (mois == null || mois < 0 || loyer == null || loyer <= 0) return null;
    return libelleAvance(avanceMois: mois, loyerMensuel: loyer);
  }

  Future<void> _choisirDateDebut() async {
    final maintenant = _now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateDebut,
      firstDate: DateTime(maintenant.year - 10),
      lastDate: DateTime(maintenant.year + 5, 12, 31),
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
        _dateDebut = picked;
        _dateDebutController.text = formatDateLongue(picked);
      });
    }
  }

  void _onContinuer() {
    final erreurs = <String, String?>{
      'duree': validerDureeBail(_entier(_dureeController)),
      'loyer': validerLoyerBail(_montant(_loyerController)),
      'caution': validerMontantPositifOuNul(_montant(_cautionController)),
      'charges': validerMontantPositifOuNul(_montant(_chargesController)),
      'avance': validerAvanceMois(_entier(_avanceController)),
      'jour': validerJourEcheance(_entier(_jourEcheanceController)),
      'conditions': validerConditionsParticulieres(
        _conditionsController.text.trim(),
      ),
    };
    setState(() => _erreurs = erreurs);
    if (erreurs.values.any((e) => e != null)) return;
    _ouvrirRecapitulatif();
  }

  void _ouvrirRecapitulatif() {
    final lot = _lot!;
    final loyer = _montant(_loyerController)!;
    final duree = _entier(_dureeController)!;
    final avanceMois = _entier(_avanceController)!;
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => ValueListenableBuilder<bool>(
        valueListenable: _envoiEnCours,
        builder: (context, enCours, _) => _RecapitulatifSheet(
          lignes: [
            ('Lot', _libelleLot(lot)),
            ('Propriétaire', lot.ownerName ?? '—'),
            ('Locataire', _locataire?.displayName ?? '—'),
            ('Début', formatDateLongue(_dateDebut)),
            ('Durée', '$duree mois'),
            ('Fin prévue', formatDateLongue(calculerDateFinBail(_dateDebut, duree))),
            ('Loyer mensuel', formatFcfa(loyer)),
            ('Charges mensuelles', formatFcfa(_montant(_chargesController)!)),
            ('Caution', formatFcfa(_montant(_cautionController)!)),
            ('Avance', libelleAvance(avanceMois: avanceMois, loyerMensuel: loyer)),
            ("Jour d'échéance", 'le ${_entier(_jourEcheanceController)} du mois'),
          ],
          conditions: _conditionsController.text.trim(),
          enCours: enCours,
          onModifier: () => Navigator.of(sheetContext).pop(),
          onConfirmer: () => _confirmerEnvoi(sheetContext),
        ),
      ),
    );
  }

  Future<void> _confirmerEnvoi(BuildContext sheetContext) async {
    if (_envoiEnCours.value) return; // garde anti-double-appui
    _envoiEnCours.value = true;

    final lot = _lot!;
    final result = await BauxRepository.instance.creerBail(
      tenantId: _locataire!.id,
      lotId: lot.id,
      ownerId: lot.ownerId!,
      dateDebut: _dateDebut,
      dureeMois: _entier(_dureeController)!,
      loyerMensuel: _montant(_loyerController)!,
      caution: _montant(_cautionController)!,
      avanceMois: _entier(_avanceController)!,
      chargesMensuelles: _montant(_chargesController)!,
      jourEcheance: _entier(_jourEcheanceController)!,
      conditionsParticulieres: _conditionsController.text,
    );
    if (!mounted) return;
    if (sheetContext.mounted) Navigator.of(sheetContext).pop();

    switch (result) {
      case CreerBailSuccess(:final bail):
        // Le lot est désormais `occupe` côté serveur : listes rafraîchies
        // en arrière-plan pour les autres écrans.
        unawaited(BiensRepository.instance.listLots());
        unawaited(LocatairesRepository.instance.refresh());
        await _apresSucces(bail);
      case CreerBailLotDejaAffecte(:final message):
        // Retour à la sélection du lot, aucun nouvel essai automatique.
        setState(() {
          _lotsRefuses.add(lot.id);
          _lot = null;
          _locataire = null;
          _historique.clear();
          _etape = _Etape.lot;
          _avisLot =
              '$message. Le lot ${_libelleLot(lot)} n\'est plus proposé : '
              'choisissez un autre lot.';
        });
        _chargerLots();
      case CreerBailValidationFailed(:final message):
        setState(
          () => _avisFormulaire =
              'Le serveur a refusé ces informations : $message',
        );
      case CreerBailPermissionRefusee():
        setState(
          () => _avisFormulaire =
              "Vous n'avez pas l'autorisation de créer un bail pour ce "
              'propriétaire.',
        );
      case CreerBailNetworkError():
        // Jamais de nouvel envoi automatique : le bail a pu être créé.
        setState(
          () => _avisFormulaire =
              'Une erreur réseau est survenue. Le bail a peut-être tout de '
              'même été créé : vérifiez le lot et la fiche du locataire '
              'avant de ressaisir.',
        );
        unawaited(BiensRepository.instance.listLots());
      case CreerBailFailure(:final message, :final type):
        // 5xx : l'INSERT a pu réussir avant l'échec (route non
        // transactionnelle) — même prudence que pour une erreur réseau.
        setState(
          () => _avisFormulaire = type == ApiExceptionType.server
              ? '$message Le bail a peut-être tout de même été créé : '
                    'vérifiez avant de ressaisir.'
              : message,
        );
    }
  }

  Future<void> _apresSucces(BailCree bail) async {
    await showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _SuccesSheet(
        reference: bail.referenceBail ?? 'n°${bail.id}',
        onTerminer: () {
          Navigator.of(sheetContext).pop();
          // `true` : signale un changement à l'écran d'origine.
          Navigator.of(context).pop(true);
        },
      ),
    );
  }

  static String _libelleLot(Lot lot) => [lot.reference, lot.immeubleNom]
      .whereType<String>()
      .where((s) => s.isNotEmpty)
      .join(' · ');

  // ── Rendu ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(title: _titreEtape, onBack: _precedent),
            Expanded(child: _corpsEtape),
          ],
        ),
      ),
    );
  }

  String get _titreEtape => switch (_etape) {
    _Etape.lot => 'Choisir un lot',
    _Etape.locataire => 'Choisir un locataire',
    _Etape.formulaire => 'Nouveau contrat de bail',
  };

  Widget get _corpsEtape => switch (_etape) {
    _Etape.lot => _buildEtapeLot(),
    _Etape.locataire => _buildEtapeLocataire(),
    _Etape.formulaire => _buildEtapeFormulaire(),
  };

  Widget _buildEtapeLot() {
    if (_loadingLots) return const _Chargement();
    if (_erreurLots != null && BiensRepository.instance.lots.isEmpty) {
      return _Erreur(message: _erreurLots!, onRetry: _chargerLots);
    }
    final recherche = _rechercheLotController.text.trim().toLowerCase();
    final lots = _lotsDisponibles
        .where(
          (l) =>
              recherche.isEmpty ||
              _libelleLot(l).toLowerCase().contains(recherche) ||
              (l.ownerName ?? '').toLowerCase().contains(recherche),
        )
        .toList();
    final sansProprietaire = _lotsDisponiblesSansProprietaire;
    final avis = _avisLot;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Column(
            children: [
              if (avis != null) ...[
                AppWarningBanner(text: avis),
                const SizedBox(height: 8),
              ],
              AppTextField(
                controller: _rechercheLotController,
                hintText: 'Rechercher un lot disponible...',
                prefixIcon: Icon(LucideIcons.search, size: 18, color: AppColors.mutedForeground),
              ),
              if (sansProprietaire > 0) ...[
                const SizedBox(height: 8),
                AppInfoBanner(
                  text:
                      '$sansProprietaire lot(s) disponible(s) sans propriétaire '
                      'rattaché ne peuvent pas recevoir de bail.',
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: lots.isEmpty
              ? const _MessageCentre(text: 'Aucun lot disponible.')
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: lots.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) =>
                      _LotRow(lot: lots[i], libelle: _libelleLot(lots[i]), onTap: () => _onSelectLot(lots[i])),
                ),
        ),
      ],
    );
  }

  Widget _buildEtapeLocataire() {
    if (_loadingLocataires) return const _Chargement();
    if (_erreurLocataires != null && LocatairesRepository.instance.items.isEmpty) {
      return _Erreur(message: _erreurLocataires!, onRetry: _chargerLocataires);
    }
    final recherche = _rechercheLocataireController.text.trim().toLowerCase();
    final locataires = _locatairesDuProprietaire
        .where(
          (l) =>
              recherche.isEmpty ||
              l.displayName.toLowerCase().contains(recherche) ||
              l.telephonePrincipal.contains(recherche),
        )
        .toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Column(
            children: [
              AppInfoBanner(
                text:
                    'Locataires de ${_lot?.ownerName ?? 'ce propriétaire'} '
                    '(propriétaire du lot ${_lot == null ? '' : _libelleLot(_lot!)}).',
              ),
              const SizedBox(height: 8),
              AppTextField(
                controller: _rechercheLocataireController,
                hintText: 'Rechercher un locataire...',
                prefixIcon: Icon(LucideIcons.search, size: 18, color: AppColors.mutedForeground),
              ),
            ],
          ),
        ),
        Expanded(
          child: locataires.isEmpty
              ? const _MessageCentre(
                  text:
                      'Aucun locataire rattaché à ce propriétaire. Créez-le '
                      "d'abord depuis Contacts.",
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: locataires.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) => _LocataireRow(
                    locataire: locataires[i],
                    onTap: () => _onSelectLocataire(locataires[i]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: AppTypography.labelUppercase(color: AppColors.mutedForeground, fontSize: 11),
    ),
  );

  Widget _champNombre({
    required String label,
    required TextEditingController controller,
    required String cle,
    String? helper,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _label(label),
      AppTextField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        errorText: _erreurs[cle],
        helperText: helper,
      ),
    ],
  );

  Widget _buildEtapeFormulaire() {
    final lot = _lot;
    final avis = _avisFormulaire;
    final dateFin = _dateFinCalculee;
    final conversionAvance = _libelleAvanceCourant;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        if (avis != null) ...[
          AppWarningBanner(text: avis),
          const SizedBox(height: 12),
        ],
        _label('LOT'),
        Text(lot == null ? '—' : _libelleLot(lot), style: AppTypography.body(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        _label('PROPRIÉTAIRE (BAILLEUR)'),
        Text(lot?.ownerName ?? '—', style: AppTypography.body(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        _label('LOCATAIRE'),
        Text(_locataire?.displayName ?? '—', style: AppTypography.body(fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),

        _label('DATE DE DÉBUT'),
        AppTextField(
          readOnly: true,
          onTap: _choisirDateDebut,
          controller: _dateDebutController,
          suffixIcon: Icon(LucideIcons.calendar, size: 16, color: AppColors.mutedForeground),
        ),
        const SizedBox(height: 16),

        _champNombre(
          label: 'DURÉE (MOIS)',
          controller: _dureeController,
          cle: 'duree',
          helper: dateFin == null ? null : 'Fin prévue : ${formatDateLongue(dateFin)}',
        ),
        const SizedBox(height: 16),

        _champNombre(label: 'LOYER MENSUEL (FCFA)', controller: _loyerController, cle: 'loyer'),
        const SizedBox(height: 16),
        _champNombre(label: 'CHARGES MENSUELLES (FCFA)', controller: _chargesController, cle: 'charges'),
        const SizedBox(height: 16),
        _champNombre(label: 'CAUTION (FCFA)', controller: _cautionController, cle: 'caution'),
        const SizedBox(height: 16),
        _champNombre(
          label: 'AVANCE (MOIS DE LOYER)',
          controller: _avanceController,
          cle: 'avance',
          helper: conversionAvance == null ? null : 'Avance : $conversionAvance',
        ),
        const SizedBox(height: 16),
        _champNombre(label: "JOUR D'ÉCHÉANCE (1-31)", controller: _jourEcheanceController, cle: 'jour'),
        const SizedBox(height: 16),

        _label('CONDITIONS PARTICULIÈRES / USAGE'),
        AppTextField(
          controller: _conditionsController,
          maxLines: 4,
          hintText: 'Ex. Usage commercial, meublé…',
          inputFormatters: [
            LengthLimitingTextInputFormatter(conditionsParticulieresMaxLength),
          ],
          errorText: _erreurs['conditions'],
          helperText:
              '${_conditionsController.text.length} / $conditionsParticulieresMaxLength',
        ),
        const SizedBox(height: 24),

        AppButton.primary(
          label: 'Continuer',
          onPressed: _onContinuer,
          icon: const Icon(LucideIcons.circle_check, size: 18, color: Colors.white),
        ),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.title, required this.onBack});

  final String title;
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
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.titleScreen(fontSize: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chargement extends StatelessWidget {
  const _Chargement();

  @override
  Widget build(BuildContext context) => const Center(child: CircularProgressIndicator());
}

class _MessageCentre extends StatelessWidget {
  const _MessageCentre({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: AppTypography.bodySmall(color: AppColors.mutedForeground),
      ),
    ),
  );
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
          Text(message, textAlign: TextAlign.center, style: AppTypography.bodySmall(color: AppColors.mutedForeground)),
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: const Text('Réessayer')),
        ],
      ),
    ),
  );
}

class _LotRow extends StatelessWidget {
  const _LotRow({required this.lot, required this.libelle, required this.onTap});
  final Lot lot;
  final String libelle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(libelle, style: AppTypography.body(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(
                  [
                    lot.ownerName,
                    if (lot.loyer != null) '${formatFcfa(lot.loyer!)} / mois',
                  ].whereType<String>().join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption(color: AppColors.mutedForeground),
                ),
              ],
            ),
          ),
          Icon(LucideIcons.chevron_right, size: 18, color: AppColors.mutedForeground),
        ],
      ),
    );
  }
}

class _LocataireRow extends StatelessWidget {
  const _LocataireRow({required this.locataire, required this.onTap});
  final Locataire locataire;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          AppAvatar(initials: locataire.initials, isCircle: true, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(locataire.displayName, style: AppTypography.body(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(locataire.telephonePrincipal, style: AppTypography.caption(color: AppColors.mutedForeground)),
              ],
            ),
          ),
          Icon(LucideIcons.chevron_right, size: 18, color: AppColors.mutedForeground),
        ],
      ),
    );
  }
}

class _RecapitulatifSheet extends StatelessWidget {
  const _RecapitulatifSheet({
    required this.lignes,
    required this.conditions,
    required this.enCours,
    required this.onModifier,
    required this.onConfirmer,
  });

  final List<(String, String)> lignes;
  final String conditions;
  final bool enCours;
  final VoidCallback onModifier;
  final VoidCallback onConfirmer;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Confirmer le bail', style: AppTypography.titleSection()),
            const SizedBox(height: 16),
            for (final (label, value) in lignes) _RecapRow(label: label, value: value),
            if (conditions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Conditions particulières', style: AppTypography.bodySmall(color: AppColors.mutedForeground)),
              const SizedBox(height: 4),
              Text(conditions, style: AppTypography.bodySmall(color: AppColors.foreground)),
            ],
            const SizedBox(height: 12),
            const AppInfoBanner(
              text:
                  'Le lot passera à « occupé ». Aucun PDF ni échéancier '
                  "n'est généré par cette action.",
            ),
            const SizedBox(height: 20),
            AppButton.primary(label: 'Confirmer', isLoading: enCours, onPressed: enCours ? null : onConfirmer),
            const SizedBox(height: 10),
            AppButton.secondary(label: 'Modifier', onPressed: enCours ? null : onModifier),
          ],
        ),
      ),
    );
  }
}

class _RecapRow extends StatelessWidget {
  const _RecapRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.bodySmall(color: AppColors.mutedForeground)),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySmall(color: AppColors.foreground).copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccesSheet extends StatelessWidget {
  const _SuccesSheet({required this.reference, required this.onTerminer});

  final String reference;
  final VoidCallback onTerminer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(color: AppColors.positiveSoft, shape: BoxShape.circle),
            child: Icon(LucideIcons.circle_check, color: AppColors.positive, size: 30),
          ),
          const SizedBox(height: 14),
          Text('Bail $reference créé', textAlign: TextAlign.center, style: AppTypography.titleScreen(fontSize: 20)),
          const SizedBox(height: 8),
          Text(
            'Le contrat PDF et l’échéancier se gèrent séparément.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall(color: AppColors.mutedForeground),
          ),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, child: AppButton.secondary(label: 'Terminer', onPressed: onTerminer)),
        ],
      ),
    );
  }
}
