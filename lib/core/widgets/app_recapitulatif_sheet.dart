import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'app_button.dart';

/// Affiche [AppRecapitulatifSheet] avant un envoi, sans fermeture par
/// geste (ni appui hors de la feuille, ni glissement) : seuls « Modifier »
/// (ferme la feuille) et « Confirmer » ([onConfirmer], qui reçoit le
/// contexte de la feuille pour la fermer après l'envoi) en sortent.
///
/// La feuille suit [envoiEnCours] (voir `VerrouEnvoi`) ; [contenu] et
/// [badge] sont réévalués à chaque changement de cet état. [defilable] :
/// feuille haute (90 % de l'écran au plus) et défilante.
Future<void> afficherRecapitulatifEnvoi(
  BuildContext context, {
  required ValueListenable<bool> envoiEnCours,
  required String titre,
  Widget Function()? badge,
  bool defilable = false,
  required List<Widget> Function() contenu,
  required void Function(BuildContext sheetContext) onConfirmer,
}) async {
  await showModalBottomSheet(
    context: context,
    isDismissible: false,
    enableDrag: false,
    isScrollControlled: defilable,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => ValueListenableBuilder<bool>(
      valueListenable: envoiEnCours,
      builder: (context, enCours, _) => AppRecapitulatifSheet(
        titre: titre,
        badge: badge?.call(),
        defilable: defilable,
        enCours: enCours,
        onModifier: () => Navigator.of(sheetContext).pop(),
        onConfirmer: () => onConfirmer(sheetContext),
        children: contenu(),
      ),
    ),
  );
}

/// Feuille récapitulatif : titre (badge facultatif), contenu propre à
/// chaque formulaire, puis « Confirmer »/« Modifier », tous deux inactifs
/// pendant l'envoi.
class AppRecapitulatifSheet extends StatelessWidget {
  const AppRecapitulatifSheet({
    super.key,
    required this.titre,
    this.badge,
    this.defilable = false,
    required this.enCours,
    required this.onModifier,
    required this.onConfirmer,
    required this.children,
  });

  final String titre;
  final Widget? badge;
  final bool defilable;
  final bool enCours;
  final VoidCallback onModifier;
  final VoidCallback onConfirmer;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final badge = this.badge;
    final colonne = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (badge != null)
          Row(
            children: [
              Expanded(child: Text(titre, style: AppTypography.titleSection())),
              badge,
            ],
          )
        else
          Text(titre, style: AppTypography.titleSection()),
        const SizedBox(height: 16),
        ...children,
        const SizedBox(height: 20),
        // Empilés (pas côte à côte) : « Confirmer » doit rester lisible
        // avec son indicateur de chargement, à toute taille de police
        // système — un partage en deux moitiés serrait trop ce texte.
        AppButton.primary(
          label: 'Confirmer',
          isLoading: enCours,
          onPressed: enCours ? null : onConfirmer,
        ),
        const SizedBox(height: 10),
        AppButton.secondary(
          label: 'Modifier',
          onPressed: enCours ? null : onModifier,
        ),
      ],
    );
    final media = MediaQuery.of(context);
    return Container(
      constraints: defilable
          ? BoxConstraints(maxHeight: media.size.height * 0.9)
          : null,
      padding: EdgeInsets.fromLTRB(20, 20, 20, media.viewInsets.bottom + 20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: defilable ? SingleChildScrollView(child: colonne) : colonne,
    );
  }
}

/// Ligne « libellé … valeur » d'une feuille récapitulatif.
class AppRecapRow extends StatelessWidget {
  const AppRecapRow({
    super.key,
    required this.label,
    required this.value,
    this.maxLines = 1,
    this.espacement,
  });

  final String label;
  final String value;

  /// Lignes de la valeur avant troncature.
  final int maxLines;

  /// Écart minimal entre libellé et valeur (aucun si `null`).
  final double? espacement;

  @override
  Widget build(BuildContext context) {
    final espacement = this.espacement;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodySmall(color: AppColors.mutedForeground),
          ),
          if (espacement != null) SizedBox(width: espacement),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySmall(color: AppColors.foreground)
                  .copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
