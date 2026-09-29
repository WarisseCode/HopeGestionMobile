import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../core/config/app_config.dart';
import '../../../core/design_system.dart';
import '../../locataires/data/locataire_results.dart';
import '../../locataires/data/locataires_repository.dart';
import '../../locataires/models/locataire.dart';
import '../data/finances_repository.dart';
import '../data/finances_results.dart';
import '../models/echeance.dart';
import '../models/finance_file_opener.dart';
import '../models/finance_format.dart';
import '../models/finance_parsing.dart' show formatDateIso;

/// Étape courante du parcours d'encaissement. L'écran peut sauter la
/// première (locataire connu à l'avance) ou la deuxième (un seul bail actif)
/// selon le contexte — voir [_EncaisserScreenState._historique].
enum _Etape { locataire, bail, echeance, formulaire }

const List<String> _modesPaiement = ['especes', 'mobile_money', 'virement', 'cheque'];

/// Un bail est considéré actif pour la sélection automatique s'il porte l'un
/// de ces statuts — même définition que `LocataireDetailScreen` (fiche
/// locataire, section « Situation des loyers »).
bool _bailEstActif(TenantLease b) => b.statut == 'actif' || b.statut == 'signe';

/// Règles de validation du formulaire, en fonctions pures (testables sans
/// widget). Tolérance d'un demi-franc sur le montant : évite qu'un reste dû
/// avec arrondi (le champ en est pré-rempli) se rejette lui-même.
@visibleForTesting
String? validerMontantEncaissement(double? montant, double resteDu) {
  if (montant == null || montant <= 0) {
    return 'Indiquez un montant supérieur à 0.';
  }
  if (montant > resteDu + 0.5) {
    return 'Le montant dépasse le reste dû (${formatMontant(resteDu)}).';
  }
  return null;
}

/// [date] et [aujourdhui] comparées jour civil (l'heure est ignorée) : une
/// date future refusée, sinon acceptée jusqu'à aujourd'hui inclus.
@visibleForTesting
String? validerDateEncaissement(DateTime date, DateTime aujourdhui) {
  final jourDate = DateTime(date.year, date.month, date.day);
  final jourAujourdhui = DateTime(aujourdhui.year, aujourdhui.month, aujourdhui.day);
  if (jourDate.isAfter(jourAujourdhui)) {
    return 'La date ne peut pas être dans le futur.';
  }
  return null;
}

/// Formulaire d'encaissement d'un loyer par échéance
/// (`PUT /api/finances/schedules/:id/pay`, voir HopeGestionV2 T-006/T-007).
///
/// Parcours : Locataire → Bail → Échéance → Formulaire → récapitulatif
/// (feuille de confirmation) → envoi. Les étapes Locataire et/ou Bail sont
/// sautées quand elles n'offrent aucun choix réel : [locataireId] connu, ou
/// un seul bail actif pour le locataire.
class EncaisserScreen extends StatefulWidget {
  const EncaisserScreen({super.key, this.locataireId, this.maintenant});

  /// Depuis la fiche locataire : saute l'étape de recherche.
  final int? locataireId;

  /// Horloge injectable (tests) : date du jour par défaut du formulaire et
  /// borne « jamais dans le futur ». `DateTime.now` sinon.
  final DateTime Function()? maintenant;

  @override
  State<EncaisserScreen> createState() => _EncaisserScreenState();
}

class _EncaisserScreenState extends State<EncaisserScreen> {
  late final DateTime Function() _now = widget.maintenant ?? DateTime.now;

  late _Etape _etape;

  /// Étapes déjà quittées, dans l'ordre — permet un retour arrière correct
  /// quel que soit le chemin réellement suivi (étapes sautées comprises) :
  /// [_allerA] y empile l'étape qu'on quitte, [_precedent] la dépile. Vide au
  /// tout début du parcours effectivement affiché → un retour à ce moment-là
  /// ferme l'écran.
  final List<_Etape> _historique = [];

  // Étape Locataire.
  final _rechercheController = TextEditingController();
  String _recherche = '';
  bool _loadingLocataires = false;
  String? _erreurLocataires;

  // Étape Bail (chargée avec le détail du locataire, qui donne aussi les baux).
  Locataire? _locataire;
  List<TenantLease> _baux = [];
  bool _loadingBaux = false;
  String? _erreurBaux;

  // Étape Échéance.
  TenantLease? _bail;
  List<Echeance> _echeances = [];
  bool _loadingEcheances = false;
  String? _erreurEcheances;

  /// Message d'avertissement affiché une fois en haut de l'étape Échéance
  /// après un 409 ou une erreur réseau pendant l'envoi (voir
  /// [_revenirAuxEcheancesAvecAvis]) — effacé dès qu'on quitte l'étape.
  String? _avisEcheance;

  // Étape Formulaire.
  Echeance? _echeance;
  final _montantController = TextEditingController();
  final _referenceController = TextEditingController();
  // Affichage seul (`readOnly`) : le choix passe par `_choisirDate`
  // (sélecteur de date), jamais par la saisie du champ.
  final _dateController = TextEditingController();
  String _modePaiement = _modesPaiement.first;
  late DateTime _datePaiement;
  String? _erreurMontant;
  String? _erreurDate;

  /// Verrou d'envoi : vérifié et posé de façon synchrone avant tout appel
  /// réseau, donc un double appui (même avant le premier repaint) ne peut
  /// jamais déclencher une deuxième requête.
  final ValueNotifier<bool> _envoiEnCours = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    _datePaiement = _dateDuJour();
    _dateController.text = formatDateLongue(_datePaiement);
    final locataireId = widget.locataireId;
    if (locataireId != null) {
      // `_etape` vaut `bail` seulement le temps du chargement initial (voir
      // `_chargerDetailInitial`) : rien n'est affiché avant que le résultat
      // (bail unique actif → passage direct à l'échéance, sinon liste des
      // baux) ne soit connu.
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
    _referenceController.dispose();
    _dateController.dispose();
    _envoiEnCours.dispose();
    super.dispose();
  }

  DateTime _dateDuJour() {
    final n = _now();
    return DateTime(n.year, n.month, n.day);
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

  /// Chargement initial quand [EncaisserScreen.locataireId] est fourni :
  /// `_etape` est déjà `bail`, donc pas d'[_allerA] ici (aucune étape
  /// précédente à mémoriser — un retour à ce stade ferme l'écran).
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

  /// Sélection automatique s'il n'y a qu'un seul bail actif parmi ceux du
  /// locataire : passe directement à l'étape Échéance. Sinon (aucun bail
  /// actif, ou plusieurs), affiche la liste — y compris les baux inactifs,
  /// jamais masqués silencieusement.
  void _apresChargementBaux() {
    // L'utilisateur a pu revenir en arrière pendant le chargement : ne
    // remplace l'étape que si "bail" est toujours celle affichée (ou en
    // cours d'affichage).
    if (_etape != _Etape.bail) return;
    final actifs = _baux.where(_bailEstActif).toList();
    if (actifs.length != 1) return; // liste affichée, l'étape reste "bail"

    final bail = actifs.single;
    // Remplacement en place, sans `_allerA` : l'entrée d'historique correcte
    // (celle qui précédait "bail") a déjà été posée en y entrant — que ce
    // soit `_onSelectLocataire` (empile `locataire`) ou le chargement
    // initial via `locataireId` (n'empile rien, `bail` n'a jamais été
    // affiché). "bail" lui-même ne doit apparaître ni à l'écran ni dans
    // l'historique puisqu'il n'offrait aucun choix réel.
    setState(() {
      _bail = bail;
      _etape = _Etape.echeance;
    });
    _chargerEcheances(bail.id);
  }

  void _onSelectBail(TenantLease b) {
    setState(() => _bail = b);
    _allerA(_Etape.echeance, depuis: _Etape.bail);
    _chargerEcheances(b.id);
  }

  // ── Chargement : Échéance ─────────────────────────────────────────────

  Future<void> _chargerEcheances(int leaseId) async {
    setState(() {
      _loadingEcheances = true;
      _erreurEcheances = null;
    });
    final result = await FinancesRepository.instance.listEcheances(leaseId);
    if (!mounted) return;
    switch (result) {
      case EcheancesListSuccess(:final items):
        final ouvertes = items.where((e) => !e.estSoldee).toList()
          ..sort(_parDateEcheance);
        setState(() {
          _echeances = ouvertes;
          _loadingEcheances = false;
        });
      case EcheancesListFailure(:final message):
        setState(() {
          _loadingEcheances = false;
          _erreurEcheances = message;
        });
    }
  }

  static int _parDateEcheance(Echeance a, Echeance b) {
    final da = a.dateEcheance;
    final db = b.dateEcheance;
    if (da == null && db == null) return 0;
    if (da == null) return 1; // sans date : après les échéances datées
    if (db == null) return -1;
    return da.compareTo(db);
  }

  void _onSelectEcheance(Echeance e) {
    setState(() {
      _echeance = e;
      _montantController.text = e.resteDu.round().toString();
      _referenceController.clear();
      _modePaiement = _modesPaiement.first;
      _datePaiement = _dateDuJour();
      _dateController.text = formatDateLongue(_datePaiement);
      _erreurMontant = null;
      _erreurDate = null;
      _avisEcheance = null;
    });
    _allerA(_Etape.formulaire, depuis: _Etape.echeance);
  }

  /// Ferme le formulaire, revient à l'étape Échéance (jamais de nouvel envoi
  /// automatique) avec un message d'avertissement, et recharge la liste pour
  /// montrer l'état réel du serveur avant toute nouvelle tentative.
  void _revenirAuxEcheancesAvecAvis(String message) {
    setState(() {
      _etape = _historique.isNotEmpty ? _historique.removeLast() : _Etape.echeance;
      _avisEcheance = message;
    });
    final bailId = _bail?.id;
    if (bailId != null) _chargerEcheances(bailId);
  }

  // ── Formulaire ────────────────────────────────────────────────────────

  double? _montantSaisi() {
    final texte = _montantController.text.trim().replaceAll(' ', '');
    if (texte.isEmpty) return null;
    return double.tryParse(texte);
  }

  String? _validerMontant() =>
      validerMontantEncaissement(_montantSaisi(), _echeance!.resteDu);

  String? _validerDate() => validerDateEncaissement(_datePaiement, _dateDuJour());

  bool get _estUnAcompte {
    final montant = _montantSaisi();
    if (montant == null || _echeance == null) return false;
    return montant < _echeance!.resteDu - 0.5;
  }

  Future<void> _choisirDate() async {
    final premiere = DateTime(_now().year - 3);
    final picked = await showDatePicker(
      context: context,
      initialDate: _datePaiement,
      firstDate: premiere,
      lastDate: _dateDuJour(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.foreground,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _datePaiement = picked;
        _dateController.text = formatDateLongue(_datePaiement);
        _erreurDate = null;
      });
    }
  }

  void _onContinuer() {
    final erreurMontant = _validerMontant();
    final erreurDate = _validerDate();
    setState(() {
      _erreurMontant = erreurMontant;
      _erreurDate = erreurDate;
    });
    if (erreurMontant != null || erreurDate != null) return;
    _ouvrirRecapitulatif();
  }

  void _ouvrirRecapitulatif() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => ValueListenableBuilder<bool>(
        valueListenable: _envoiEnCours,
        builder: (context, enCours, _) => _RecapitulatifSheet(
          locataireNom: _locataire?.displayName ?? '—',
          bailLibelle: [
            _bail?.refLot,
            _bail?.buildingName,
          ].whereType<String>().where((s) => s.isNotEmpty).join(' · '),
          echeance: _echeance!,
          montant: _montantSaisi() ?? 0,
          modePaiement: _modePaiement,
          date: _datePaiement,
          estAcompte: _estUnAcompte,
          reference: _referenceController.text.trim(),
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

    final montant = _montantSaisi() ?? 0;
    final reference = _referenceController.text.trim();
    final result = await FinancesRepository.instance.payerEcheance(
      echeanceId: _echeance!.id,
      montant: montant,
      modePaiement: _modePaiement,
      datePaiement: formatDateIso(_datePaiement),
      reference: reference.isEmpty ? null : reference,
    );
    if (!mounted) return;
    _envoiEnCours.value = false;
    if (!sheetContext.mounted) return; // feuille déjà fermée entre-temps

    switch (result) {
      case PayerEcheanceSuccess(:final message, :final receiptUrl):
        Navigator.of(sheetContext).pop();
        _apresSucces(message: message, receiptUrl: receiptUrl);
      case PayerEcheanceValidationFailed(:final message):
        // 400 : reste sur le formulaire, rien n'est perdu (contrôleurs intacts).
        Navigator.of(sheetContext).pop();
        setState(() => _erreurMontant = message);
      case PayerEcheanceDejaSoldee(:final message):
        Navigator.of(sheetContext).pop();
        _revenirAuxEcheancesAvecAvis(message);
      case PayerEcheanceFailure():
        // Réseau ou délai dépassé : jamais de nouvel envoi automatique —
        // l'utilisateur revoit l'échéancier réel avant toute nouvelle tentative.
        Navigator.of(sheetContext).pop();
        _revenirAuxEcheancesAvecAvis(
          "Une erreur réseau est survenue. L'encaissement a peut-être tout "
          'de même été enregistré : vérifiez l\'échéance ci-dessous avant '
          'de réessayer.',
        );
    }
  }

  Future<void> _apresSucces({required String message, String? receiptUrl}) async {
    await showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _SuccesSheet(
        message: message,
        receiptUrl: receiptUrl,
        onOuvrirQuittance: (url) => ouvrirFichierOuCopier(sheetContext, url),
        onTerminer: () {
          Navigator.of(sheetContext).pop();
          // `true` : signale un changement à l'écran d'origine — celui-ci
          // recharge de toute façon dans tous les cas (voir call sites).
          Navigator.of(context).pop(true);
        },
      ),
    );
  }

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
    _Etape.echeance => 'Choisir une échéance',
    _Etape.formulaire => 'Encaisser un loyer',
  };

  Widget get _corpsEtape => switch (_etape) {
    _Etape.locataire => _buildEtapeLocataire(),
    _Etape.bail => _buildEtapeBail(),
    _Etape.echeance => _buildEtapeEcheance(),
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

  Widget _buildEtapeEcheance() {
    if (_loadingEcheances) return const _Chargement();
    if (_erreurEcheances != null) {
      return _Erreur(
        message: _erreurEcheances!,
        onRetry: () {
          final bailId = _bail?.id;
          if (bailId != null) _chargerEcheances(bailId);
        },
      );
    }
    final avis = _avisEcheance;
    return Column(
      children: [
        if (avis != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: AppWarningBanner(text: avis),
          ),
        Expanded(
          child: _echeances.isEmpty
              ? const _MessageCentre(
                  text:
                      "Aucune échéance ouverte pour ce bail. Les échéances se "
                      'génèrent depuis le web.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: _echeances.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) => _EcheanceRow(
                    echeance: _echeances[i],
                    maintenant: _now(),
                    onTap: () => _onSelectEcheance(_echeances[i]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildEtapeFormulaire() {
    final echeance = _echeance!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                echeance.description?.trim().isNotEmpty == true
                    ? echeance.description!
                    : 'Échéance',
                style: AppTypography.body(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              if (echeance.dateEcheance != null)
                Text(
                  'Échéance : ${formatDateLongue(echeance.dateEcheance!)}',
                  style: AppTypography.caption(color: AppColors.mutedForeground),
                ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Reste dû', style: AppTypography.bodySmall(color: AppColors.mutedForeground)),
                  Text(
                    formatMontant(echeance.resteDu),
                    style: AppTypography.body(fontWeight: FontWeight.w700, color: AppColors.primary),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        Text('MONTANT REÇU', style: AppTypography.labelUppercase(color: AppColors.mutedForeground, fontSize: 11)),
        const SizedBox(height: 6),
        AppTextField(
          controller: _montantController,
          keyboardType: const TextInputType.numberWithOptions(),
          hintText: echeance.resteDu.round().toString(),
          errorText: _erreurMontant,
          prefixIcon: Icon(LucideIcons.coins, size: 16, color: AppColors.mutedForeground),
          onChanged: (_) => setState(() {}), // rafraîchit le libellé « acompte »
        ),
        if (_erreurMontant == null && _estUnAcompte) ...[
          const SizedBox(height: 6),
          Text(
            'Ce montant est un acompte : l\'échéance restera partiellement due.',
            style: AppTypography.caption(color: AppColors.warning),
          ),
        ],
        const SizedBox(height: 16),

        Text('MODE DE RÈGLEMENT', style: AppTypography.labelUppercase(color: AppColors.mutedForeground, fontSize: 11)),
        const SizedBox(height: 6),
        AppDropdown<String>(
          value: _modePaiement,
          items: _modesPaiement
              .map((m) => AppDropdownItem(label: libelleModePaiement(m), value: m))
              .toList(),
          onChanged: (val) {
            if (val != null) setState(() => _modePaiement = val);
          },
        ),
        const SizedBox(height: 16),

        Text('DATE DU PAIEMENT', style: AppTypography.labelUppercase(color: AppColors.mutedForeground, fontSize: 11)),
        const SizedBox(height: 6),
        AppTextField(
          readOnly: true,
          onTap: _choisirDate,
          controller: _dateController,
          errorText: _erreurDate,
          suffixIcon: Icon(LucideIcons.calendar, size: 16, color: AppColors.mutedForeground),
        ),
        const SizedBox(height: 16),

        Text(
          'RÉFÉRENCE / TRANSACTION (FACULTATIF)',
          style: AppTypography.labelUppercase(color: AppColors.mutedForeground, fontSize: 10.5),
        ),
        const SizedBox(height: 6),
        AppTextField(
          controller: _referenceController,
          hintText: 'Ex: TRX-2026-987410 / N° Chèque',
          prefixIcon: Icon(LucideIcons.hash, size: 16, color: AppColors.mutedForeground),
        ),
        const SizedBox(height: 24),

        AppButton.primary(label: 'Continuer', onPressed: _onContinuer, icon: const Icon(LucideIcons.circle_check, size: 18, color: Colors.white)),
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

class _EcheanceRow extends StatelessWidget {
  const _EcheanceRow({required this.echeance, required this.maintenant, required this.onTap});
  final Echeance echeance;
  final DateTime maintenant;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final etat = echeance.etat(maintenant: maintenant);
    final (label, type) = switch (etat) {
      EtatEcheance.enRetard => ('En retard', AppBadgeType.danger),
      EtatEcheance.acompte => ('Acompte', AppBadgeType.warning),
      _ => ('À payer', AppBadgeType.neutral),
    };
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
                  echeance.description?.trim().isNotEmpty == true ? echeance.description!.trim() : 'Échéance #${echeance.id}',
                  style: AppTypography.body(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (echeance.dateEcheance != null)
                  Text(formatDateLongue(echeance.dateEcheance!), style: AppTypography.caption(color: AppColors.mutedForeground)),
                if (echeance.estAcompte)
                  Text(
                    'Versé ${formatMontant(echeance.montantPaye)} · Reste ${formatMontant(echeance.resteDu)}',
                    style: AppTypography.caption(color: AppColors.warning),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(formatMontant(echeance.resteDu), style: AppTypography.body(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              AppBadge(label: label, type: type),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecapitulatifSheet extends StatelessWidget {
  const _RecapitulatifSheet({
    required this.locataireNom,
    required this.bailLibelle,
    required this.echeance,
    required this.montant,
    required this.modePaiement,
    required this.date,
    required this.estAcompte,
    required this.reference,
    required this.enCours,
    required this.onModifier,
    required this.onConfirmer,
  });

  final String locataireNom;
  final String bailLibelle;
  final Echeance echeance;
  final double montant;
  final String modePaiement;
  final DateTime date;
  final bool estAcompte;
  final String reference;
  final bool enCours;
  final VoidCallback onModifier;
  final VoidCallback onConfirmer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Confirmer l\'encaissement', style: AppTypography.titleSection())),
              AppBadge(
                label: estAcompte ? 'ACOMPTE' : 'SOLDE',
                type: estAcompte ? AppBadgeType.warning : AppBadgeType.positive,
                isUppercase: true,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _RecapRow(label: 'Locataire', value: locataireNom),
          if (bailLibelle.isNotEmpty) _RecapRow(label: 'Bail', value: bailLibelle),
          _RecapRow(
            label: 'Échéance',
            value: echeance.dateEcheance != null ? formatDateLongue(echeance.dateEcheance!) : 'Échéance #${echeance.id}',
          ),
          _RecapRow(label: 'Montant', value: formatMontant(montant)),
          _RecapRow(label: 'Mode', value: libelleModePaiement(modePaiement)),
          _RecapRow(label: 'Date', value: formatDateLongue(date)),
          if (reference.isNotEmpty) _RecapRow(label: 'Référence', value: reference),
          const SizedBox(height: 20),
          // Empilés (pas côte à côte) : « Confirmer » doit rester lisible
          // avec son indicateur de chargement, à toute taille de police
          // système — un partage en deux moitiés serrait trop ce texte.
          AppButton.primary(label: 'Confirmer', isLoading: enCours, onPressed: onConfirmer),
          const SizedBox(height: 10),
          AppButton.secondary(label: 'Modifier', onPressed: enCours ? null : onModifier),
        ],
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
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              maxLines: 1,
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
  const _SuccesSheet({
    required this.message,
    required this.receiptUrl,
    required this.onOuvrirQuittance,
    required this.onTerminer,
  });

  final String message;
  final String? receiptUrl;
  final void Function(String url) onOuvrirQuittance;
  final VoidCallback onTerminer;

  @override
  Widget build(BuildContext context) {
    final url = receiptUrl;
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
          Text(message, textAlign: TextAlign.center, style: AppTypography.titleScreen(fontSize: 20)),
          const SizedBox(height: 24),
          if (url != null && url.isNotEmpty) ...[
            SizedBox(
              width: double.infinity,
              child: AppButton.primary(
                label: 'Ouvrir la quittance',
                icon: const Icon(LucideIcons.file_text, size: 18, color: Colors.white),
                onPressed: () => onOuvrirQuittance(AppConfig.resolveFileUrl(url)),
              ),
            ),
            const SizedBox(height: 10),
          ],
          SizedBox(width: double.infinity, child: AppButton.secondary(label: 'Terminer', onPressed: onTerminer)),
        ],
      ),
    );
  }
}
