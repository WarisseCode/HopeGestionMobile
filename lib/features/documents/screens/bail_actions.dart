import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../core/design_system.dart';
import '../../../core/network/api_exception.dart';
import '../../finances/models/finance_format.dart';
import '../data/baux_repository.dart';
import '../data/baux_results.dart';
import '../models/bail_detail.dart';

/// Issue d'une feuille/écran d'action sur un bail, renvoyée à
/// `BailDetailScreen` à la fermeture (`null` = annulé sans aucun envoi
/// à l'issue incertaine).
enum IssueActionBail {
  /// 2xx : action appliquée.
  succes,

  /// Au moins un envoi s'est soldé par une erreur réseau ou serveur :
  /// l'action a peut-être été appliquée, la fiche doit être rechargée.
  incertain,
}

/// Message utilisateur pour un échec d'action, et si l'action a pu être
/// appliquée malgré l'erreur (routes non transactionnelles). `null` pour
/// un succès.
({String message, bool incertain})? decrireEchecActionBail(
  ActionBailResult result,
) {
  const verifier =
      'L\'opération a peut-être été appliquée malgré l\'erreur : vérifiez '
      'la fiche du bail avant de réessayer.';
  return switch (result) {
    ActionBailSuccess() => null,
    ActionBailValidationFailed(:final message) => (
      message: 'Le serveur a refusé ces informations : $message',
      incertain: false,
    ),
    ActionBailPermissionRefusee() => (
      message: 'Votre compte n\'a pas l\'autorisation de modifier les baux.',
      incertain: false,
    ),
    ActionBailNetworkError() => (
      message: 'Une erreur réseau est survenue. $verifier',
      incertain: true,
    ),
    ActionBailFailure(:final message, :final type) =>
      type == ApiExceptionType.server
          ? (message: '$message $verifier', incertain: true)
          : (message: message, incertain: false),
  };
}

/// Logique d'envoi commune aux trois actions : verrou anti-double-envoi,
/// aucun nouvel essai automatique, fermeture avec [IssueActionBail].
mixin EnvoiActionBail<T extends StatefulWidget> on State<T> {
  bool envoiEnCours = false;
  String? erreur;
  bool _incertain = false;

  /// Un seul appel à la fois ; succès → fermeture avec
  /// [IssueActionBail.succes] ; échec → message affiché, bouton
  /// réactivé (nouvel essai manuel uniquement).
  Future<void> envoyer(Future<ActionBailResult> Function() appel) async {
    if (envoiEnCours) return;
    setState(() {
      envoiEnCours = true;
      erreur = null;
    });
    final result = await appel();
    if (!mounted) return;
    final echec = decrireEchecActionBail(result);
    if (echec == null) {
      Navigator.of(context).pop(IssueActionBail.succes);
      return;
    }
    setState(() {
      envoiEnCours = false;
      erreur = echec.message;
      _incertain = _incertain || echec.incertain;
    });
  }

  /// Fermeture sans succès : signale une issue incertaine si un envoi a
  /// échoué de façon ambiguë. Impossible pendant un envoi.
  void fermer() {
    if (envoiEnCours) return;
    Navigator.of(context).pop(_incertain ? IssueActionBail.incertain : null);
  }

  /// Intercepte le retour système pour passer par [fermer].
  Widget avecRetourControle(Widget child) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) fermer();
    },
    child: child,
  );
}

/// Ouvre la feuille de résiliation.
Future<IssueActionBail?> ouvrirResiliationBail(
  BuildContext context,
  BailDetail bail, {
  DateTime Function()? maintenant,
}) => showModalBottomSheet<IssueActionBail>(
  context: context,
  isDismissible: false,
  enableDrag: false,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  builder: (_) => ResilierBailSheet(bail: bail, maintenant: maintenant),
);

/// Ouvre la feuille de renouvellement.
Future<IssueActionBail?> ouvrirRenouvellementBail(
  BuildContext context,
  BailDetail bail, {
  DateTime Function()? maintenant,
}) => showModalBottomSheet<IssueActionBail>(
  context: context,
  isDismissible: false,
  enableDrag: false,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  builder: (_) => RenouvelerBailSheet(bail: bail, maintenant: maintenant),
);

/// Résiliation : motif libre optionnel (500 caractères max) et date de
/// résiliation (aujourd'hui par défaut, toujours envoyée).
class ResilierBailSheet extends StatefulWidget {
  const ResilierBailSheet({super.key, required this.bail, this.maintenant});

  final BailDetail bail;
  final DateTime Function()? maintenant;

  @override
  State<ResilierBailSheet> createState() => _ResilierBailSheetState();
}

class _ResilierBailSheetState extends State<ResilierBailSheet>
    with EnvoiActionBail {
  final _motifController = TextEditingController();
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    _date = _jour(widget.maintenant?.call() ?? DateTime.now());
  }

  @override
  void dispose() {
    _motifController.dispose();
    super.dispose();
  }

  Future<void> _choisirDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(_date.year - 5),
      lastDate: DateTime(_date.year + 5, 12, 31),
      builder: _themeCalendrier,
    );
    if (picked != null && mounted) setState(() => _date = picked);
  }

  void _confirmer() => envoyer(
    () => BauxRepository.instance.resilierBail(
      widget.bail.id,
      motif: _motifController.text,
      dateResiliation: _date,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return avecRetourControle(
      _FeuilleAction(
        titre: 'Résilier le bail',
        children: [
          const AppInfoBanner(
            text:
                'Le bail passera à « résilié » et le lot redeviendra '
                'disponible.',
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: 'Motif (optionnel)',
            hintText: 'Ex. départ du locataire',
            helperText:
                '${BauxRepository.motifResiliationMaxLength} caractères '
                'maximum',
            controller: _motifController,
            maxLines: 3,
            enabled: !envoiEnCours,
            inputFormatters: [
              LengthLimitingTextInputFormatter(
                BauxRepository.motifResiliationMaxLength,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _ChampDate(
            label: 'Date de résiliation',
            valeur: formatDateLongue(_date),
            onTap: envoiEnCours ? null : _choisirDate,
          ),
          if (erreur != null) ...[
            const SizedBox(height: 14),
            MessageErreurActionBail(erreur!),
          ],
          const SizedBox(height: 20),
          AppButton.danger(
            label: 'Confirmer',
            isLoading: envoiEnCours,
            onPressed: envoiEnCours ? null : _confirmer,
          ),
          const SizedBox(height: 10),
          AppButton.secondary(
            label: 'Annuler',
            onPressed: envoiEnCours ? null : fermer,
          ),
        ],
      ),
    );
  }
}

/// Renouvellement : nouvelle date de fin **obligatoire** (le serveur
/// écraserait `date_fin` à NULL si elle était omise) et nouveau loyer
/// optionnel, pré-rempli avec le loyer actuel.
class RenouvelerBailSheet extends StatefulWidget {
  const RenouvelerBailSheet({super.key, required this.bail, this.maintenant});

  final BailDetail bail;
  final DateTime Function()? maintenant;

  @override
  State<RenouvelerBailSheet> createState() => _RenouvelerBailSheetState();
}

class _RenouvelerBailSheetState extends State<RenouvelerBailSheet>
    with EnvoiActionBail {
  late final TextEditingController _loyerController;
  late final DateTime _aujourdhui;
  DateTime? _dateFin;
  String? _erreurDate;
  String? _erreurLoyer;

  @override
  void initState() {
    super.initState();
    _aujourdhui = _jour(widget.maintenant?.call() ?? DateTime.now());
    final loyer = widget.bail.loyerMensuel;
    _loyerController = TextEditingController(
      text: loyer == null ? '' : loyer.round().toString(),
    );
  }

  @override
  void dispose() {
    _loyerController.dispose();
    super.dispose();
  }

  /// Première date de fin admise : demain, et après la date de début.
  DateTime get _premiereDate {
    final demain = _aujourdhui.add(const Duration(days: 1));
    final debut = widget.bail.dateDebut;
    if (debut == null) return demain;
    final lendemainDebut = _jour(debut).add(const Duration(days: 1));
    return lendemainDebut.isAfter(demain) ? lendemainDebut : demain;
  }

  Future<void> _choisirDate() async {
    final premiere = _premiereDate;
    final derniere = DateTime(premiere.year + 30, 12, 31);
    // Proposition : un an après la fin actuelle (ou après aujourd'hui).
    final base = widget.bail.dateFin ?? _aujourdhui;
    var initiale = _dateFin ?? DateTime(base.year + 1, base.month, base.day);
    if (initiale.isBefore(premiere)) initiale = premiere;
    if (initiale.isAfter(derniere)) initiale = derniere;
    final picked = await showDatePicker(
      context: context,
      initialDate: initiale,
      firstDate: premiere,
      lastDate: derniere,
      builder: _themeCalendrier,
    );
    if (picked != null && mounted) {
      setState(() {
        _dateFin = picked;
        _erreurDate = null;
      });
    }
  }

  /// `null` = champ vide (loyer non envoyé) ; `NaN` = saisie invalide.
  double? _loyerSaisi() {
    final brut = _loyerController.text.replaceAll(RegExp(r'\s'), '');
    if (brut.isEmpty) return null;
    return double.tryParse(brut.replaceAll(',', '.')) ?? double.nan;
  }

  void _confirmer() {
    final dateFin = _dateFin;
    final loyer = _loyerSaisi();
    setState(() {
      _erreurDate = dateFin == null
          ? 'Choisissez la nouvelle date de fin du bail.'
          : null;
      _erreurLoyer = loyer != null && (loyer.isNaN || loyer <= 0)
          ? 'Saisissez un loyer supérieur à 0, ou laissez le champ vide.'
          : null;
    });
    if (_erreurDate != null || _erreurLoyer != null || dateFin == null) return;
    // Loyer inchangé : non envoyé (aucune révision de loyer côté serveur).
    final nouveauLoyer = loyer == widget.bail.loyerMensuel ? null : loyer;
    envoyer(
      () => BauxRepository.instance.renouvelerBail(
        widget.bail.id,
        nouvelleDateFin: dateFin,
        nouveauLoyer: nouveauLoyer,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFin = _dateFin;
    return avecRetourControle(
      _FeuilleAction(
        titre: 'Renouveler le bail',
        children: [
          AppInfoBanner(
            text:
                'Le bail repassera à « actif ». Le lot n\'est pas modifié. '
                'Fin actuelle : '
                '${widget.bail.dateFin == null ? 'non renseignée' : formatDateLongue(widget.bail.dateFin!)}.',
          ),
          const SizedBox(height: 16),
          _ChampDate(
            label: 'Nouvelle date de fin *',
            valeur: dateFin == null
                ? 'Choisir une date'
                : formatDateLongue(dateFin),
            onTap: envoiEnCours ? null : _choisirDate,
            erreur: _erreurDate,
          ),
          const SizedBox(height: 14),
          AppTextField(
            label: 'Nouveau loyer mensuel (optionnel)',
            hintText: 'Loyer inchangé si vide',
            controller: _loyerController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            enabled: !envoiEnCours,
            errorText: _erreurLoyer,
            suffixIcon: Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                'F',
                style: AppTypography.bodySmall(
                  color: AppColors.mutedForeground,
                ),
              ),
            ),
          ),
          if (erreur != null) ...[
            const SizedBox(height: 14),
            MessageErreurActionBail(erreur!),
          ],
          const SizedBox(height: 20),
          AppButton.primary(
            label: 'Confirmer',
            isLoading: envoiEnCours,
            onPressed: envoiEnCours ? null : _confirmer,
          ),
          const SizedBox(height: 10),
          AppButton.secondary(
            label: 'Annuler',
            onPressed: envoiEnCours ? null : fermer,
          ),
        ],
      ),
    );
  }
}

DateTime _jour(DateTime d) => DateTime(d.year, d.month, d.day);

Widget _themeCalendrier(BuildContext context, Widget? child) => Theme(
  data: Theme.of(context).copyWith(
    colorScheme: ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: AppColors.primaryForeground,
      onSurface: AppColors.foreground,
    ),
  ),
  child: child!,
);

class _FeuilleAction extends StatelessWidget {
  const _FeuilleAction({required this.titre, required this.children});

  final String titre;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Container(
      constraints: BoxConstraints(maxHeight: media.size.height * 0.9),
      padding: EdgeInsets.fromLTRB(20, 20, 20, media.viewInsets.bottom + 20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titre, style: AppTypography.titleSection()),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _ChampDate extends StatelessWidget {
  const _ChampDate({
    required this.label,
    required this.valeur,
    required this.onTap,
    this.erreur,
  });

  final String label;
  final String valeur;
  final VoidCallback? onTap;
  final String? erreur;

  @override
  Widget build(BuildContext context) {
    final erreur = this.erreur;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.bodySmall(color: AppColors.foreground),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: AppRadius.borderSm,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: AppRadius.borderSm,
              border: Border.all(
                color: erreur != null ? AppColors.error : AppColors.inputBorder,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  LucideIcons.calendar,
                  size: 18,
                  color: AppColors.mutedForeground,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    valeur,
                    style: AppTypography.bodySmall(color: AppColors.foreground),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (erreur != null) ...[
          const SizedBox(height: 6),
          Text(erreur, style: AppTypography.caption(color: AppColors.error)),
        ],
      ],
    );
  }
}

/// Bandeau d'erreur d'envoi, partagé avec `SignerBailScreen`.
class MessageErreurActionBail extends StatelessWidget {
  const MessageErreurActionBail(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.errorSoft,
        borderRadius: AppRadius.borderMd,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.circle_alert, size: 16, color: AppColors.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySmall(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
