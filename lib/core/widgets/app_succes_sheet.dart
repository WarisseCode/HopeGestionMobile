import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Affiche [AppSuccesSheet] après un envoi réussi, sans fermeture par
/// geste (ni appui hors de la feuille, ni glissement).
///
/// [actions] reçoit le contexte de la feuille et `terminer`, qui ferme la
/// feuille puis l'écran du formulaire ([context]) avec `true` pour
/// signaler un changement à l'écran d'origine.
Future<void> afficherSuccesEnvoi(
  BuildContext context, {
  required String titre,
  String? sousTitre,
  required List<Widget> Function(
    BuildContext sheetContext,
    VoidCallback terminer,
  )
  actions,
}) async {
  await showModalBottomSheet(
    context: context,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => AppSuccesSheet(
      titre: titre,
      sousTitre: sousTitre,
      actions: actions(sheetContext, () {
        Navigator.of(sheetContext).pop();
        Navigator.of(context).pop(true);
      }),
    ),
  );
}

/// Feuille de succès : pastille cochée, titre, sous-titre facultatif et
/// boutons d'action.
class AppSuccesSheet extends StatelessWidget {
  const AppSuccesSheet({
    super.key,
    required this.titre,
    this.sousTitre,
    required this.actions,
  });

  final String titre;
  final String? sousTitre;

  /// Empilés pleine largeur plutôt que côte à côte : à 390 px, deux
  /// `AppButton` en ligne débordent (libellés non flexibles).
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final sousTitre = this.sousTitre;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.positiveSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(
              LucideIcons.circle_check,
              color: AppColors.positive,
              size: 30,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            titre,
            textAlign: TextAlign.center,
            style: AppTypography.titleScreen(fontSize: 20),
          ),
          if (sousTitre != null) ...[
            const SizedBox(height: 8),
            Text(
              sousTitre,
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall(color: AppColors.mutedForeground),
            ),
          ],
          const SizedBox(height: 24),
          for (final (i, action) in actions.indexed) ...[
            if (i > 0) const SizedBox(height: 10),
            SizedBox(width: double.infinity, child: action),
          ],
        ],
      ),
    );
  }
}
