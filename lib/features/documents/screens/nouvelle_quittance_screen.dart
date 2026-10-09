import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../core/design_system.dart';
import '../../../core/network/api_exception.dart';
import '../../locataires/data/locataire_results.dart';
import '../../locataires/data/locataires_repository.dart';
import '../../locataires/models/locataire.dart';
import '../data/documents_repository.dart';
import '../data/documents_results.dart';
import '../models/document.dart';
import '../../finances/models/finance_format.dart';
import '../../finances/models/finance_parsing.dart' show formatDateIso;

/// Étape courante du parcours de création d'une quittance manuelle. Les
/// étapes Locataire et/ou Bail sont sautées quand elles n'offrent aucun
/// choix réel — même principe que `EncaisserScreen`.
enum _Etape { locataire, bail, formulaire }

/// Même définition qu'`EncaisserScreen`/`LocataireDetailScreen` : un bail
/// est considéré actif pour la sélection automatique s'il porte l'un de ces
/// statuts.
bool _bailEstActif(TenantLease b) => b.statut == 'actif' || b.statut == 'signe';

/// Règles de validation du formulaire, en fonctions pures (testables sans
/// widget) — même principe qu'`EncaisserScreen`.
@visibleForTesting
String? validerMontantQuittance(double? montant) {
  if (montant == null || montant <= 0) {
    return 'Indiquez un montant supérieur à 0.';
  }
  return null;
}

/// [periode] et [maintenant] comparées au mois civil (jour ignoré) : un mois
/// futur est refusé, le mois courant accepté.
@visibleForTesting
String? validerPeriodeQuittance(DateTime periode, DateTime maintenant) {
  final moisPeriode = DateTime(periode.year, periode.month);
  final moisMaintenant = DateTime(maintenant.year, maintenant.month);
  if (moisPeriode.isAfter(moisMaintenant)) {
    return 'La période ne peut pas être dans le futur.';
  }
  return null;
}

/// [date] et [maintenant] comparées jour civil (l'heure est ignorée).
@visibleForTesting
String? validerDateEmissionQuittance(DateTime date, DateTime maintenant) {
  final jourDate = DateTime(date.year, date.month, date.day);
  final jourMaintenant = DateTime(maintenant.year, maintenant.month, maintenant.day);
  if (jourDate.isAfter(jourMaintenant)) {
    return 'La date ne peut pas être dans le futur.';
  }
  return null;
}

/// Formulaire de création d'une quittance manuelle
/// (`POST /api/quittances`, voir HopeGestionV2 `quittanceRoutes.ts`).
///
/// Parcours : Locataire → Bail → Formulaire → récapitulatif (feuille de
/// confirmation) → envoi. **Ceci est un document, pas un encaissement** :
/// aucun paiement n'est enregistré (voir `EncaisserScreen` pour cela). Le
/// PDF de la quittance reste une fonctionnalité de l'application web — rien
/// n'est généré ni stocké ici (voir `DocumentDetailScreen`).
class NouvelleQuittanceScreen extends StatefulWidget {
  const NouvelleQuittanceScreen({super.key, this.locataireId, this.maintenant});

  /// Depuis la fiche locataire : saute l'étape de recherche.
  final int? locataireId;

  /// Horloge injectable (tests) : mois/date du jour par défaut du
  /// formulaire et borne « jamais dans le futur ». `DateTime.now` sinon.
  final DateTime Function()? maintenant;

  @override
  State<NouvelleQuittanceScreen> createState() =>
      _NouvelleQuittanceScreenState();
}

class _NouvelleQuittanceScreenState extends State<NouvelleQuittanceScreen>
    with VerrouEnvoi {
  late final DateTime Function() _now = widget.maintenant ?? DateTime.now;

  late _Etape _etape;

  /// Même rôle que dans `EncaisserScreen` : permet un retour arrière correct
  /// quel que soit le chemin réellement suivi (étapes sautées comprises).
  final List<_Etape> _historique = [];

  // Étape Locataire.
  final _rechercheController = TextEditingController();
  String _recherche = '';
  bool _loadingLocataires = false;
  String? _erreurLocataires;

  // Étape Bail.
  Locataire? _locataire;
  List<TenantLease> _baux = [];
  bool _loadingBaux = false;
  String? _erreurBaux;

  // Étape Formulaire.
  TenantLease? _bail;
  final _montantController = TextEditingController();
  final _bienController = TextEditingController();
  final _periodeController = TextEditingController();
  final _dateEmissionController = TextEditingController();
  late DateTime _periodeMois;
  late DateTime _dateEmission;
  String? _erreurMontant;
  String? _erreurPeriode;
  String? _erreurDateEmission;

  /// Message affiché en haut du formulaire après un 400/403/404 ou une
  /// erreur réseau pendant l'envoi (voir [_confirmerEnvoi]).
  String? _avisFormulaire;

  /// Vérification de doublon (même bail, même période) — voir
  /// [_chargerQuittancesExistantes]/[_doublonDetecte]. `false` tant que la
  /// liste n'a pas été chargée avec succès : on ne prétend jamais l'absence
  /// de doublon sans l'avoir vérifiée.
  bool _quittancesChargees = false;
  String? _avisVerificationDoublon;

  @override
  void initState() {
    super.initState();
    final locataireId = widget.locataireId;
    if (locataireId != null) {
      _etape = _Etape.bail;
      _loadingBaux = true;
      _chargerDetailInitial(locataireId);
    } else {
      _etape = _Etape.locataire;
      _rechercheController.addListener(
        () => setState(() => _recherche = _rechercheController.text.toLowerCase()),
      );
      _chargerLocataires();
    }
  }

  @override
  void dispose() {
    _rechercheController.dispose();
    _montantController.dispose();
    _bienController.dispose();
    _periodeController.dispose();
    _dateEmissionController.dispose();
    super.dispose();
  }

  // ── Navigation ────────────────────────────────────────────────────────

  void _allerA(_Etape destination, {required _Etape depuis}) {
    setState(() {
      _historique.add(depuis);
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

  // ── Chargement : Locataire ───────────────────────────────────────────

  Future<void> _chargerLocataires() async {
    setState(() {
      _loadingLocataires = true;
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

  void _onSelectLocataire(Locataire l) {
    setState(() => _locataire = l);
    _allerA(_Etape.bail, depuis: _Etape.locataire);
    _chargerBaux(l.id);
  }

  // ── Chargement : Bail ─────────────────────────────────────────────────

  Future<void> _chargerDetailInitial(int id) async {
    final result = await LocatairesRepository.instance.getDetail(id);
    if (!mounted) return;
    switch (result) {
      case LocataireDetailSuccess(:final locataire, :final baux):
        setState(() {
          _locataire = locataire;
          _baux = baux;
          _loadingBaux = false;
        });
        _apresChargementBaux();
      case LocataireDetailFailure(:final message):
        setState(() {
          _loadingBaux = false;
          _erreurBaux = message;
        });
    }
  }

  Future<void> _chargerBaux(int locataireId) async {
    setState(() {
      _loadingBaux = true;
      _erreurBaux = null;
    });
    final result = await LocatairesRepository.instance.getDetail(locataireId);
    if (!mounted) return;
    switch (result) {
      case LocataireDetailSuccess(:final baux):
        setState(() {
          _baux = baux;
          _loadingBaux = false;
        });
        _apresChargementBaux();
      case LocataireDetailFailure(:final message):
        setState(() {
          _loadingBaux = false;
          _erreurBaux = message;
        });
    }
  }

  /// Sélection automatique s'il n'y a qu'un seul bail actif — voir
  /// `EncaisserScreen._apresChargementBaux` pour la logique d'historique.
  void _apresChargementBaux() {
    if (_etape != _Etape.bail) return;
    final actifs = _baux.where(_bailEstActif).toList();
    if (actifs.length != 1) return;

    final bail = actifs.single;
    setState(() {
      _bail = bail;
      _etape = _Etape.formulaire;
      _initialiserFormulaire(bail);
    });
    _chargerQuittancesExistantes();
  }

  void _onSelectBail(TenantLease b) {
    setState(() {
      _bail = b;
      _initialiserFormulaire(b);
    });
    _allerA(_Etape.formulaire, depuis: _Etape.bail);
    _chargerQuittancesExistantes();
  }

  void _initialiserFormulaire(TenantLease bail) {
    final maintenant = _now();
    _periodeMois = DateTime(maintenant.year, maintenant.month);
    _periodeController.text = formatMois(_periodeMois);
    _dateEmission = DateTime(maintenant.year, maintenant.month, maintenant.day);
    _dateEmissionController.text = formatDateLongue(_dateEmission);
    _montantController.text = bail.loyerActuel != null
        ? bail.loyerActuel!.round().toString()
        : '';
    _bienController.text = [bail.refLot, bail.buildingName]
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .join(' · ');
    _erreurMontant = null;
    _erreurPeriode = null;
    _erreurDateEmission = null;
    _avisFormulaire = null;
    _quittancesChargees = false;
    _avisVerificationDoublon = null;
  }

  // ── Vérification de doublon ──────────────────────────────────────────

  /// Charge (ou recharge) les quittances manuelles existantes pour détecter
  /// un doublon bail+période — non bloquant : si la liste est indisponible
  /// (403 `finance:read` ou autre échec), [_avisVerificationDoublon] le
  /// signale sans empêcher la saisie ni l'envoi.
  Future<void> _chargerQuittancesExistantes() async {
    final result = await DocumentsRepository.instance.listQuittancesManuelles();
    if (!mounted) return;
    setState(() {
      switch (result) {
        case QuittancesManuellesSuccess():
          _quittancesChargees = true;
          _avisVerificationDoublon = null;
        case QuittancesManuellesFailure(:final type):
          _quittancesChargees = false;
          _avisVerificationDoublon = type == ApiExceptionType.forbidden
              ? "Les quittances déjà enregistrées n'ont pas pu être "
                  'vérifiées : accès non autorisé.'
              : "Les quittances déjà enregistrées n'ont pas pu être vérifiées.";
      }
    });
  }

  /// Recalculée à chaque affichage (le choix de période change sans nouvel
  /// appel réseau, la liste déjà chargée suffit).
  bool get _doublonDetecte {
    if (!_quittancesChargees) return false;
    final bail = _bail;
    if (bail == null) return false;
    final periodeLabel = formatMois(_periodeMois);
    return DocumentsRepository.instance.quittancesManuelles.any(
      (q) => q.leaseId == bail.id && q.periode == periodeLabel,
    );
  }

  // ── Formulaire ────────────────────────────────────────────────────────

  double? _montantSaisi() {
    final texte = _montantController.text.trim().replaceAll(' ', '');
    if (texte.isEmpty) return null;
    return double.tryParse(texte);
  }

  String? _validerMontant() => validerMontantQuittance(_montantSaisi());
  String? _validerPeriode() => validerPeriodeQuittance(_periodeMois, _now());
  String? _validerDateEmission() =>
      validerDateEmissionQuittance(_dateEmission, _now());

  Future<void> _choisirPeriode() async {
    final maintenant = _now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _periodeMois,
      firstDate: DateTime(maintenant.year - 3),
      lastDate: DateTime(maintenant.year, maintenant.month + 1, 0),
      initialDatePickerMode: DatePickerMode.year,
      builder: (context, child) => _themeCalendrier(context, child),
    );
    if (picked != null) {
      setState(() {
        _periodeMois = DateTime(picked.year, picked.month);
        _periodeController.text = formatMois(_periodeMois);
        _erreurPeriode = null;
      });
    }
  }

  Future<void> _choisirDateEmission() async {
    final maintenant = _now();
    final jourMaintenant = DateTime(maintenant.year, maintenant.month, maintenant.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateEmission,
      firstDate: DateTime(maintenant.year - 3),
      lastDate: jourMaintenant,
      builder: (context, child) => _themeCalendrier(context, child),
    );
    if (picked != null) {
      setState(() {
        _dateEmission = picked;
        _dateEmissionController.text = formatDateLongue(_dateEmission);
        _erreurDateEmission = null;
      });
    }
  }

  Widget _themeCalendrier(BuildContext context, Widget? child) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: ColorScheme.light(
          primary: AppColors.primary,
          onPrimary: AppColors.primaryForeground,
          onSurface: AppColors.foreground,
        ),
      ),
      child: child!,
    );
  }

  void _onContinuer() {
    final erreurMontant = _validerMontant();
    final erreurPeriode = _validerPeriode();
    final erreurDateEmission = _validerDateEmission();
    setState(() {
      _erreurMontant = erreurMontant;
      _erreurPeriode = erreurPeriode;
      _erreurDateEmission = erreurDateEmission;
    });
    if (erreurMontant != null || erreurPeriode != null || erreurDateEmission != null) {
      return;
    }
    _ouvrirRecapitulatif();
  }

  void _ouvrirRecapitulatif() {
    afficherRecapitulatifEnvoi(
      context,
      envoiEnCours: envoiEnCours,
      titre: 'Confirmer la quittance',
      contenu: () {
        final bailLibelle = [
          _bail?.refLot,
          _bail?.buildingName,
        ].whereType<String>().where((s) => s.isNotEmpty).join(' · ');
        final bien = _bienController.text.trim();
        return [
          AppRecapRow(label: 'Locataire', value: _locataire?.displayName ?? '—'),
          if (bailLibelle.isNotEmpty) AppRecapRow(label: 'Bail', value: bailLibelle),
          if (bien.isNotEmpty) AppRecapRow(label: 'Bien', value: bien),
          AppRecapRow(label: 'Période', value: formatMois(_periodeMois)),
          AppRecapRow(label: 'Montant', value: formatMontant(_montantSaisi() ?? 0)),
          AppRecapRow(label: "Date d'émission", value: formatDateLongue(_dateEmission)),
          const SizedBox(height: 12),
          if (_doublonDetecte) ...[
            const AppWarningBanner(
              text:
                  'Une quittance manuelle existe déjà pour ce bail et cette '
                  'période. Vérifiez avant de confirmer.',
            ),
            const SizedBox(height: 12),
          ],
          const AppInfoBanner(
            text:
                "Aucun paiement n'est enregistré par cette action. Le PDF "
                'est disponible sur l\'application web.',
          ),
        ];
      },
      onConfirmer: _confirmerEnvoi,
    );
  }

  Future<void> _confirmerEnvoi(BuildContext sheetContext) async {
    if (!prendreVerrouEnvoi()) return; // garde anti-double-appui

    final result = await DocumentsRepository.instance.creerQuittanceManuelle(
      leaseId: _bail!.id,
      montant: _montantSaisi() ?? 0,
      periode: formatMois(_periodeMois),
      locataire: _locataire?.displayName,
      bien: _bienController.text.trim(),
      dateEmission: formatDateIso(_dateEmission),
    );
    if (!mounted) return;
    libererVerrouEnvoi();
    if (!sheetContext.mounted) return; // feuille déjà fermée entre-temps

    switch (result) {
      case CreerQuittanceManuelleSuccess(:final quittance):
        Navigator.of(sheetContext).pop();
        _apresSucces(quittance);
      case CreerQuittanceManuelleValidationFailed(:final message):
        // 400 : reste sur le formulaire, rien n'est perdu (contrôleurs intacts).
        Navigator.of(sheetContext).pop();
        setState(() => _avisFormulaire = message);
      case CreerQuittanceManuelleBailRefuse(:final message):
        Navigator.of(sheetContext).pop();
        setState(() => _avisFormulaire = message);
      case CreerQuittanceManuelleNetworkError():
        // Jamais de nouvel envoi automatique : on recharge la liste pour
        // montrer l'état réel avant toute nouvelle tentative.
        Navigator.of(sheetContext).pop();
        setState(() {
          _avisFormulaire =
              'Une erreur réseau est survenue. La quittance a peut-être '
              'tout de même été créée : vérifiez la liste avant de '
              'réessayer.';
        });
        _chargerQuittancesExistantes();
      case CreerQuittanceManuelleFailure(:final message):
        Navigator.of(sheetContext).pop();
        setState(() => _avisFormulaire = message);
    }
  }

  Future<void> _apresSucces(QuittanceManuelle quittance) => afficherSuccesEnvoi(
    context,
    titre: 'Quittance ${quittance.numero ?? '—'} créée',
    sousTitre:
        "Aucun paiement n'a été enregistré. Le PDF est disponible sur "
        "l'application web.",
    actions: (_, terminer) => [
      AppButton.secondary(label: 'Terminer', onPressed: terminer),
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
            _TopBar(title: _titreEtape, onBack: _precedent),
            Expanded(child: _corpsEtape),
          ],
        ),
      ),
    );
  }

  String get _titreEtape => switch (_etape) {
    _Etape.locataire => 'Choisir un locataire',
    _Etape.bail => 'Choisir un bail',
    _Etape.formulaire => 'Quittance manuelle',
  };

  Widget get _corpsEtape => switch (_etape) {
    _Etape.locataire => _buildEtapeLocataire(),
    _Etape.bail => _buildEtapeBail(),
    _Etape.formulaire => _buildEtapeFormulaire(),
  };

  Widget _buildEtapeLocataire() {
    if (_loadingLocataires) return const _Chargement();
    if (_erreurLocataires != null) {
      return _Erreur(message: _erreurLocataires!, onRetry: _chargerLocataires);
    }
    final tous = LocatairesRepository.instance.items;
    final filtres = _recherche.isEmpty
        ? tous
        : tous
              .where(
                (l) =>
                    l.displayName.toLowerCase().contains(_recherche) ||
                    l.telephonePrincipal.contains(_recherche),
              )
              .toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: AppTextField(
            controller: _rechercheController,
            hintText: 'Rechercher un locataire...',
            prefixIcon: Icon(LucideIcons.search, size: 18, color: AppColors.mutedForeground),
          ),
        ),
        Expanded(
          child: filtres.isEmpty
              ? const _MessageCentre(text: 'Aucun locataire trouvé.')
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: filtres.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) => _LocataireRow(
                    locataire: filtres[i],
                    onTap: () => _onSelectLocataire(filtres[i]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildEtapeBail() {
    if (_loadingBaux) return const _Chargement();
    if (_erreurBaux != null) {
      return _Erreur(
        message: _erreurBaux!,
        onRetry: () {
          final locataireId = _locataire?.id ?? widget.locataireId;
          if (locataireId != null) _chargerBaux(locataireId);
        },
      );
    }
    if (_baux.isEmpty) {
      return const _MessageCentre(text: 'Aucun bail enregistré pour ce locataire.');
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: _baux.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, i) =>
          _BailRow(bail: _baux[i], onTap: () => _onSelectBail(_baux[i])),
    );
  }

  Widget _buildEtapeFormulaire() {
    final avis = _avisFormulaire;
    final avisDoublon = _avisVerificationDoublon;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        const AppWarningBanner(
          text:
              "Cette quittance est un document : elle n'enregistre aucun "
              'paiement. Pour un encaissement réel, utilisez Encaisser.',
        ),
        if (avis != null) ...[
          const SizedBox(height: 10),
          AppWarningBanner(text: avis),
        ],
        if (avisDoublon != null) ...[
          const SizedBox(height: 10),
          AppInfoBanner(text: avisDoublon),
        ],
        if (_doublonDetecte) ...[
          const SizedBox(height: 10),
          const AppWarningBanner(
            text:
                'Une quittance manuelle existe déjà pour ce bail et cette '
                'période.',
          ),
        ],
        const SizedBox(height: 16),

        Text('LOCATAIRE', style: AppTypography.labelUppercase(color: AppColors.mutedForeground, fontSize: 11)),
        const SizedBox(height: 6),
        Text(_locataire?.displayName ?? '—', style: AppTypography.body(fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),

        Text('BIEN', style: AppTypography.labelUppercase(color: AppColors.mutedForeground, fontSize: 11)),
        const SizedBox(height: 6),
        AppTextField(
          controller: _bienController,
          hintText: 'Bien concerné',
        ),
        const SizedBox(height: 16),

        Text('PÉRIODE', style: AppTypography.labelUppercase(color: AppColors.mutedForeground, fontSize: 11)),
        const SizedBox(height: 6),
        AppTextField(
          readOnly: true,
          onTap: _choisirPeriode,
          controller: _periodeController,
          errorText: _erreurPeriode,
          suffixIcon: Icon(LucideIcons.calendar, size: 16, color: AppColors.mutedForeground),
        ),
        const SizedBox(height: 16),

        Text('MONTANT (FCFA)', style: AppTypography.labelUppercase(color: AppColors.mutedForeground, fontSize: 11)),
        const SizedBox(height: 6),
        AppTextField(
          controller: _montantController,
          keyboardType: const TextInputType.numberWithOptions(),
          errorText: _erreurMontant,
          prefixIcon: Icon(LucideIcons.coins, size: 16, color: AppColors.mutedForeground),
        ),
        const SizedBox(height: 16),

        Text("DATE D'ÉMISSION", style: AppTypography.labelUppercase(color: AppColors.mutedForeground, fontSize: 11)),
        const SizedBox(height: 6),
        AppTextField(
          readOnly: true,
          onTap: _choisirDateEmission,
          controller: _dateEmissionController,
          errorText: _erreurDateEmission,
          suffixIcon: Icon(LucideIcons.calendar, size: 16, color: AppColors.mutedForeground),
        ),
        const SizedBox(height: 24),

        AppButton.primary(
          label: 'Continuer',
          onPressed: _onContinuer,
          icon: Icon(LucideIcons.circle_check, size: 18, color: AppColors.primaryForeground),
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

class _BailRow extends StatelessWidget {
  const _BailRow({required this.bail, required this.onTap});
  final TenantLease bail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final libelle = [bail.refLot, bail.buildingName].whereType<String>().where((s) => s.isNotEmpty).join(' · ');
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  libelle.isEmpty ? 'Bail #${bail.id}' : libelle,
                  style: AppTypography.body(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (bail.loyerActuel != null)
                  Text('${formatMontant(bail.loyerActuel!)} / mois', style: AppTypography.caption(color: AppColors.mutedForeground)),
              ],
            ),
          ),
          AppBadge(
            label: bail.statut.isEmpty ? '—' : bail.statut,
            type: _bailEstActif(bail) ? AppBadgeType.positive : AppBadgeType.neutral,
          ),
        ],
      ),
    );
  }
}
